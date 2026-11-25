// EN: Single source of truth for user-defined alerts at runtime — the exact
//     counterpart of TripRepository, with one extra responsibility: whenever
//     the alerts OR the trips change, it recomputes each enabled alert's
//     projected reach date (pure DayCounter math over actual + planned trips)
//     and hands the resulting schedule to the AlertScheduler.
//
//     POSITIONING (PLAN.md): this class never invents an alert, a threshold,
//     or a default — it only stores and schedules what the user explicitly
//     created. Zero alerts is the shipped state.
//
// FR: Source de vérité unique pour les alertes définies par l'utilisateur à
//     l'exécution — l'exact pendant de TripRepository, avec une responsabilité
//     de plus : à chaque changement des alertes OU des séjours, il recalcule la
//     date d'atteinte projetée de chaque alerte active (calcul pur DayCounter
//     sur les séjours réels + planifiés) et remet l'horaire résultant à
//     l'AlertScheduler.
//
//     POSITIONNEMENT (PLAN.md) : cette classe n'invente jamais une alerte, un
//     seuil ou une valeur par défaut — elle ne stocke et planifie que ce que
//     l'utilisateur a explicitement créé. Zéro alerte est l'état livré.

import 'package:flutter/foundation.dart';

import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class AlertRepository extends ChangeNotifier {
  final StorageService _storage;
  final TripRepository _tripRepository;

  // EN: Nullable so unit tests (and any future platform without notification
  //     support) can run the repository with no scheduler at all — persistence
  //     and state behave identically, only OS scheduling is skipped.
  // FR: Nullable pour que les tests unitaires (et toute plateforme future sans
  //     support de notifications) puissent exécuter le dépôt sans aucun
  //     planificateur — persistance et état se comportent pareil, seule la
  //     planification OS est omise.
  final AlertScheduler? _scheduler;

  final List<DayAlert> _alerts = [];

  // EN: Clock injection for testability — production uses DateTime.now.
  // FR: Injection d'horloge pour la testabilité — la production utilise
  //     DateTime.now.
  final DateTime Function() _now;

  AlertRepository(
    this._storage,
    this._tripRepository, {
    AlertScheduler? scheduler,
    DateTime Function()? now,
  })  : _scheduler = scheduler,
        _now = now ?? DateTime.now {
    _alerts.addAll(_storage.loadAlerts());

    // EN: Trips are an input to every reach-date projection, so any trip
    //     mutation must trigger a reschedule. The listener is removed in
    //     dispose() to avoid leaking this repository through the trip one.
    // FR: Les séjours sont une entrée de chaque projection de date d'atteinte,
    //     donc toute mutation de séjour doit déclencher une replanification. Le
    //     listener est retiré dans dispose() pour ne pas faire fuir ce dépôt à
    //     travers celui des séjours.
    _tripRepository.addListener(_onTripsChanged);
  }

  // EN: Alerts sorted by threshold (smallest target first) — a stable, neutral
  //     ordering. Unmodifiable view, same contract as TripRepository.trips.
  // FR: Alertes triées par seuil (plus petite cible d'abord) — un ordre stable
  //     et neutre. Vue non modifiable, même contrat que TripRepository.trips.
  List<DayAlert> get alerts {
    final sorted = List<DayAlert>.from(_alerts)
      ..sort((a, b) => a.thresholdDays.compareTo(b.thresholdDays));
    return List.unmodifiable(sorted);
  }

  int get alertCount => _alerts.length;

  Future<void> addAlert(DayAlert alert) => _commit([..._alerts, alert]);

  Future<void> updateAlert(DayAlert updated) async {
    final index = _alerts.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    await _commit([..._alerts]..[index] = updated);
  }

  Future<void> deleteAlert(String id) async {
    final kept = _alerts.where((a) => a.id != id).toList();
    if (kept.length != _alerts.length) await _commit(kept);
  }

  // EN: Publish the new list immediately so a following call builds on it, and put
  //     the old one back if the device refuses the write: the screen must not show
  //     an alert that was not saved.
  // FR: Publier la nouvelle liste tout de suite pour qu'un appel suivant parte
  //     d'elle, et remettre l'ancienne si l'appareil refuse l'écriture : l'écran ne
  //     doit pas montrer une alerte non enregistrée.
  Future<void> _commit(List<DayAlert> next) async {
    final previous = List.of(_alerts);
    _replace(next);
    try {
      await _storage.saveAlerts(next);
    } on StorageWriteException {
      _replace(previous);
      notifyListeners();
      rethrow;
    }
    await refresh();
    notifyListeners();
  }

  void _replace(List<DayAlert> next) => _alerts
    ..clear()
    ..addAll(next);

  // EN: Compute the current schedule: for each ENABLED alert, project the
  //     first date its user-set target is reached (actual + planned trips —
  //     projecting forward is the feature), derive the delivery moment from
  //     the user's chosen time and lead, and keep only moments still in the
  //     future. Exposed for the UI (to display "projected for …") and used
  //     internally before every handoff to the scheduler.
  // FR: Calculer l'horaire courant : pour chaque alerte ACTIVE, projeter la
  //     première date où sa cible est atteinte (séjours réels + planifiés — la
  //     projection est la raison d'être), dériver l'instant de livraison de
  //     l'heure et du préavis choisis, et ne garder que les instants encore
  //     futurs. Exposé pour l'interface (afficher « projeté pour… ») et utilisé
  //     en interne avant chaque remise au planificateur.
  List<ScheduledAlert> computeSchedule() {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final trips = _tripRepository.trips;

    final schedule = <ScheduledAlert>[];
    for (final alert in _alerts) {
      if (!alert.enabled) continue;

      final reachDate = _reachDate(alert, trips, today);
      if (reachDate == null) continue;

      final fireMoment = alert.fireMomentFor(reachDate);
      if (!fireMoment.isAfter(now)) continue;

      schedule.add(
        ScheduledAlert(
          alert: alert,
          reachDate: reachDate,
          fireMoment: fireMoment,
        ),
      );
    }
    return schedule;
  }

  // EN: Re-project a single alert's reach date for display purposes (returns
  //     null when the target is never reached with the current trip data).
  // FR: Reprojeter la date d'atteinte d'une seule alerte pour l'affichage
  //     (retourne null quand la cible n'est jamais atteinte avec les données
  //     de séjour actuelles).
  DateTime? projectedReachDate(DayAlert alert) {
    final now = _now();
    return _reachDate(
      alert,
      _tripRepository.trips,
      DateTime(now.year, now.month, now.day),
    );
  }

  // EN: Whether the target is met as of today — arithmetic for display, so a past
  //     crossing is not shown as "not reached". No judgment is attached to it.
  // FR: Si la cible est atteinte en date d'aujourd'hui — arithmétique pour
  //     l'affichage, pour qu'un franchissement passé ne soit pas montré comme « non
  //     atteint ». Aucun jugement n'y est rattaché.
  bool isReached(DayAlert alert) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final trips = _tripRepository.trips;
    switch (alert.kind) {
      case AlertKind.dayCountThreshold:
        return DayCounter.countDaysInLastDays(
              trips: trips,
              days: alert.windowDays,
              today: today,
              includeStatuses: const {TripStatus.actual, TripStatus.planned},
            ) >=
            alert.thresholdDays;
      case AlertKind.sinceLastVisit:
        final reach = _reachDate(alert, trips, today);
        return reach != null && !reach.isAfter(today);
    }
  }

  // EN: Project an alert's reach date according to its kind (FR-9 / FR-10). This is
  //     the ONLY place the two alert kinds diverge — everything downstream (delivery
  //     time, lead, scheduling) is shared:
  //       • dayCountThreshold — the first date the rolling count reaches the target
  //         (actual + planned trips, since projecting forward is the point), or null
  //         if never reached;
  //       • sinceLastVisit    — the last ACTUAL departure plus the elapsed-days
  //         target, or null if the user has recorded no actual visit yet. Calendar
  //         arithmetic goes through the DateTime constructor (not Duration) so it
  //         stays DST-safe, consistent with the rest of the engine.
  // FR: Projeter la date d'atteinte d'une alerte selon son type (FR-9 / FR-10).
  //     C'est le SEUL endroit où les deux types divergent — tout l'aval (heure,
  //     préavis, planification) est partagé :
  //       • dayCountThreshold — la première date où le compte glissant atteint la
  //         cible (séjours réels + planifiés, la projection étant le but), ou null si
  //         jamais atteinte ;
  //       • sinceLastVisit    — le dernier départ RÉEL plus la cible de jours
  //         écoulés, ou null si l'utilisateur n'a encore consigné aucun séjour réel.
  //         L'arithmétique calendaire passe par le constructeur DateTime (pas
  //         Duration) pour rester sûre face à l'heure d'été, comme le reste du moteur.
  DateTime? _reachDate(DayAlert alert, List<Trip> trips, DateTime today) {
    switch (alert.kind) {
      case AlertKind.dayCountThreshold:
        return DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: alert.thresholdDays,
          windowDays: alert.windowDays,
          from: today,
          crossingOnly: true,
        );
      case AlertKind.sinceLastVisit:
        final last = DayCounter.lastDeparture(trips: trips);
        if (last == null) return null;
        return DateTime(last.year, last.month, last.day + alert.thresholdDays);
    }
  }

  Future<void> _onTripsChanged() async {
    // EN: Trip data changed — reach dates may have moved. No persistence
    //     needed (alerts themselves are unchanged), only rescheduling.
    // FR: Les données de séjour ont changé — les dates d'atteinte ont pu
    //     bouger. Pas de persistance nécessaire (les alertes elles-mêmes sont
    //     inchangées), seulement une replanification.
    await refresh();
  }

  // EN: Send the current schedule to the OS. Also called at launch, on resume and on
  //     a language change, since a phone restore, a new time zone or a new language
  //     all make the OS copy stale without any data change here.
  //
  //     Runs never overlap (a cancel from one could erase the other's work); a call
  //     made during a run triggers one more with the newest data. A failure is
  //     contained: the alert is already saved, and the next refresh retries.
  // FR: Envoyer l'horaire courant à l'OS. Aussi appelé au lancement, au retour à
  //     l'avant-plan et au changement de langue, car une restauration du téléphone,
  //     un nouveau fuseau ou une nouvelle langue périment la copie de l'OS sans
  //     aucun changement de données ici.
  //
  //     Les passes ne se chevauchent jamais (l'annulation de l'une effacerait le
  //     travail de l'autre) ; un appel pendant une passe en déclenche une de plus
  //     avec les données les plus récentes. Un échec est contenu : l'alerte est déjà
  //     enregistrée et le prochain rafraîchissement réessaie.
  Future<void> refresh() {
    if (_scheduler == null) return Future<void>.value();
    _stale = true;
    return _running ??= _drain();
  }

  bool _stale = false;
  Future<void>? _running;

  Future<void> _drain() async {
    while (_stale) {
      _stale = false;
      try {
        await _scheduler?.reschedule(computeSchedule());
      } catch (e) {
        debugPrint('[AlertRepository] Scheduling failed: ${e.runtimeType}');
        await null;
      }
    }
    _running = null;
  }

  @override
  void dispose() {
    _tripRepository.removeListener(_onTripsChanged);
    super.dispose();
  }
}
