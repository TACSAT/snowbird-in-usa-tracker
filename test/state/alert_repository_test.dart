// EN: Tests for AlertRepository — persistence, the scheduling policy (what is
//     handed to the AlertScheduler and when), and reaction to trip changes.
//     Uses a fake scheduler and mocked SharedPreferences: no platform channels.
//
// FR: Tests d'AlertRepository — persistance, politique de planification (ce qui
//     est remis à l'AlertScheduler et quand) et réaction aux changements de
//     séjours. Utilise un planificateur factice et SharedPreferences simulé :
//     aucun canal de plateforme.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

// EN: Fake scheduler that records every reschedule call for assertions.
// FR: Planificateur factice qui enregistre chaque appel de replanification
//     pour les assertions.
class RecordingScheduler implements AlertScheduler {
  final List<List<ScheduledAlert>> calls = [];
  List<ScheduledAlert> get last => calls.last;

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> reschedule(List<ScheduledAlert> schedule) async {
    calls.add(schedule);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // EN: Fixed "now" so projections are deterministic: Jan 15 2025, 12:00.
  // FR: « Maintenant » fixe pour des projections déterministes :
  //     15 jan. 2025, 12 h.
  final fixedNow = DateTime(2025, 1, 15, 12, 0);

  Future<(AlertRepository, TripRepository, RecordingScheduler)> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final tripRepo = TripRepository(storage);
    final scheduler = RecordingScheduler();
    final alertRepo = AlertRepository(
      storage,
      tripRepo,
      scheduler: scheduler,
      now: () => fixedNow,
    );
    return (alertRepo, tripRepo, scheduler);
  }

  test('adding an alert persists it and schedules the projected fire moment',
      () async {
    final (alertRepo, tripRepo, scheduler) = await build();

    // EN: 31 actual days in Dec 2024 + planned Feb–Apr trip: the 75-day target
    //     in a 365-day window is reached Mar 16 2025 (same maths as the engine
    //     test), so the notification must be scheduled for Mar 16, 09:00.
    // FR: 31 jours réels en déc. 2024 + séjour planifié fév.–avr. : la cible de
    //     75 jours dans une fenêtre de 365 jours est atteinte le 16 mars 2025
    //     (mêmes calculs que le test du moteur), donc la notification doit être
    //     planifiée le 16 mars à 9 h.
    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2024, 12, 1),
        departureDate: DateTime(2024, 12, 31),
        status: TripStatus.actual,
      ),
    );
    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 2, 1),
        departureDate: DateTime(2025, 4, 30),
        status: TripStatus.planned,
      ),
    );

    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 75,
        windowDays: 365,
        hour: 9,
        minute: 0,
      ),
    );

    expect(alertRepo.alertCount, 1);
    expect(scheduler.last, hasLength(1));
    expect(scheduler.last.single.reachDate, DateTime(2025, 3, 16));
    expect(scheduler.last.single.fireMoment, DateTime(2025, 3, 16, 9, 0));

    // EN: Reload from storage through a fresh repository — the alert survives.
    // FR: Recharger depuis le stockage via un dépôt neuf — l'alerte survit.
    final reloaded = AlertRepository(
      StorageService(await SharedPreferences.getInstance()),
      tripRepo,
      now: () => fixedNow,
    );
    expect(reloaded.alertCount, 1);
    expect(reloaded.alerts.single.thresholdDays, 75);
  });

  test('lead days shift the scheduled fire moment earlier', () async {
    final (alertRepo, tripRepo, scheduler) = await build();

    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 2, 1),
        departureDate: DateTime(2025, 4, 30),
        status: TripStatus.planned,
      ),
    );

    // EN: 10-day target inside the planned trip: reached Feb 10. With a 2-day,
    //     3-hour lead at 09:00, the notification fires Feb 8 at 06:00.
    // FR: Cible de 10 jours dans le séjour planifié : atteinte le 10 fév. Avec
    //     un préavis de 2 jours et 3 heures à 9 h, la notification part le
    //     8 fév. à 6 h.
    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 10,
        windowDays: 365,
        hour: 9,
        minute: 0,
        leadDays: 2,
        leadHours: 3,
      ),
    );

    expect(scheduler.last.single.reachDate, DateTime(2025, 2, 10));
    expect(scheduler.last.single.fireMoment, DateTime(2025, 2, 8, 6, 0));
  });

  test('disabled alerts and unreachable targets are not scheduled', () async {
    final (alertRepo, tripRepo, scheduler) = await build();

    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 2, 1),
        departureDate: DateTime(2025, 2, 5),
        status: TripStatus.planned,
      ),
    );

    // EN: Disabled alert — kept, never scheduled.
    // FR: Alerte désactivée — conservée, jamais planifiée.
    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 3,
        windowDays: 365,
        hour: 9,
        minute: 0,
        enabled: false,
      ),
    );
    // EN: Enabled but unreachable (only 5 days of trips exist).
    // FR: Active mais inatteignable (seulement 5 jours de séjours existent).
    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 100,
        windowDays: 365,
        hour: 9,
        minute: 0,
      ),
    );

    expect(alertRepo.alertCount, 2);
    expect(scheduler.last, isEmpty);
  });

  test('a trip change triggers rescheduling without touching alert storage',
      () async {
    final (alertRepo, tripRepo, scheduler) = await build();

    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 5,
        windowDays: 365,
        hour: 9,
        minute: 0,
      ),
    );
    // EN: No trips yet — nothing schedulable.
    // FR: Aucun séjour encore — rien à planifier.
    expect(scheduler.last, isEmpty);

    final callsBefore = scheduler.calls.length;
    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 3, 1),
        departureDate: DateTime(2025, 3, 31),
        status: TripStatus.planned,
      ),
    );
    // EN: Listener fired: one more reschedule, now with a projected date —
    //     5th day of the March trip is Mar 5.
    // FR: Listener déclenché : une replanification de plus, maintenant avec une
    //     date projetée — le 5e jour du séjour de mars est le 5 mars.
    expect(scheduler.calls.length, greaterThan(callsBefore));
    expect(scheduler.last.single.reachDate, DateTime(2025, 3, 5));
  });

  // EN: FR-10 — the since-last-visit alert projects from the last ACTUAL departure
  //     plus the elapsed-days target, and ignores planned trips entirely.
  // FR: FR-10 — l'alerte « depuis le dernier séjour » projette à partir du dernier
  //     départ RÉEL plus la cible de jours écoulés, et ignore complètement les
  //     séjours planifiés.
  test('since-last-visit projects last actual departure + threshold days',
      () async {
    final (alertRepo, tripRepo, scheduler) = await build();

    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2024, 12, 1),
        departureDate: DateTime(2024, 12, 31),
        status: TripStatus.actual,
      ),
    );
    // EN: A later PLANNED trip must NOT be treated as the last visit.
    // FR: Un séjour PLANIFIÉ ultérieur ne doit PAS compter comme le dernier séjour.
    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 6, 1),
        departureDate: DateTime(2025, 6, 30),
        status: TripStatus.planned,
      ),
    );

    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 30,
        windowDays: 30,
        hour: 9,
        minute: 0,
        kind: AlertKind.sinceLastVisit,
      ),
    );

    // EN: 2024-12-31 + 30 days = 2025-01-30 (future vs the fixed now).
    // FR: 2024-12-31 + 30 jours = 2025-01-30 (futur par rapport au maintenant fixe).
    expect(scheduler.last, hasLength(1));
    expect(scheduler.last.single.reachDate, DateTime(2025, 1, 30));
    expect(scheduler.last.single.fireMoment, DateTime(2025, 1, 30, 9, 0));
  });

  test('since-last-visit with no actual trip is not scheduled', () async {
    final (alertRepo, tripRepo, scheduler) = await build();

    // EN: Only a planned trip exists — there is no actual visit to measure from.
    // FR: Seul un séjour planifié existe — aucun séjour réel comme point de départ.
    await tripRepo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 3, 1),
        departureDate: DateTime(2025, 3, 31),
        status: TripStatus.planned,
      ),
    );
    await alertRepo.addAlert(
      DayAlert.create(
        thresholdDays: 30,
        windowDays: 30,
        hour: 9,
        minute: 0,
        kind: AlertKind.sinceLastVisit,
      ),
    );

    expect(alertRepo.alertCount, 1);
    expect(scheduler.last, isEmpty);
    expect(alertRepo.projectedReachDate(alertRepo.alerts.single), isNull);
  });
}
