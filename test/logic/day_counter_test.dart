// EN: Unit tests for DayCounter — the pure day-counting logic. These tests run
//     without a device, emulator, or Flutter widget tree. They exercise the
//     counting rules exhaustively so that any future change to the calculation
//     is caught immediately.
//
//     Convention: each test name states the SCENARIO and the EXPECTED OUTCOME,
//     not the implementation detail. This makes failures self-explanatory.
//
// FR: Tests unitaires pour DayCounter — la logique pure de comptage de jours.
//     Ces tests s'exécutent sans appareil, émulateur ni arbre de widgets Flutter.
//     Ils exercent exhaustivement les règles de comptage afin que tout changement
//     futur au calcul soit détecté immédiatement.
//
//     Convention : chaque nom de test énonce le SCÉNARIO et le RÉSULTAT ATTENDU,
//     et non le détail d'implémentation. Cela rend les échecs auto-explicatifs.

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

void main() {
  // EN: Helper — build a minimal actual Trip with the given dates (no UUID needed
  //     for logic tests, so we use a fixed stub ID).
  // FR: Aide — construire un Trip réel minimal avec les dates données (pas besoin
  //     d'UUID pour les tests logiques, on utilise donc un ID stub fixe).
  Trip actual(String arrival, String departure, {String id = 'test-id'}) {
    return Trip(
      id: id,
      arrivalDate: DateTime.parse(arrival),
      departureDate: DateTime.parse(departure),
      status: TripStatus.actual,
    );
  }

  Trip planned(String arrival, String departure, {String id = 'test-id-p'}) {
    return Trip(
      id: id,
      arrivalDate: DateTime.parse(arrival),
      departureDate: DateTime.parse(departure),
      status: TripStatus.planned,
    );
  }

  // ---------------------------------------------------------------------------
  // countDaysInWindow
  // ---------------------------------------------------------------------------

  group('countDaysInWindow', () {
    test('single day trip counts as 1 day', () {
      final trips = [actual('2025-01-15', '2025-01-15')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        1,
      );
    });

    test('trip entirely inside window counts all days (arrival + departure)',
        () {
      // EN: Jan 10 to Jan 12 = 3 days (10, 11, 12 all count).
      // FR: 10 jan. au 12 jan. = 3 jours (10, 11, 12 comptent tous).
      final trips = [actual('2025-01-10', '2025-01-12')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        3,
      );
    });

    test('trip partially overlapping window start is clamped', () {
      // EN: Trip Dec 28 – Jan 3, window Jan 1 – Jan 31 → only Jan 1, 2, 3 = 3.
      // FR: Séjour 28 déc. – 3 jan., fenêtre 1 jan. – 31 jan. → seulement 1, 2, 3 jan. = 3.
      final trips = [actual('2024-12-28', '2025-01-03')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        3,
      );
    });

    test('trip partially overlapping window end is clamped', () {
      // EN: Trip Jan 29 – Feb 05, window Jan 1 – Jan 31 → only Jan 29, 30, 31 = 3.
      // FR: Séjour 29 jan. – 5 fév., fenêtre 1 jan. – 31 jan. → seulement 29, 30, 31 jan. = 3.
      final trips = [actual('2025-01-29', '2025-02-05')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        3,
      );
    });

    test('trip entirely before window contributes 0 days', () {
      final trips = [actual('2024-11-01', '2024-11-30')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        0,
      );
    });

    test('trip entirely after window contributes 0 days', () {
      final trips = [actual('2025-03-01', '2025-03-31')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        0,
      );
    });

    test('multiple non-overlapping trips sum correctly', () {
      final trips = [
        actual('2025-01-05', '2025-01-07', id: 'a'), // 3 days
        actual('2025-01-15', '2025-01-17', id: 'b'), // 3 days
        actual('2025-01-25', '2025-01-27', id: 'c'), // 3 days
      ];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        9,
      );
    });

    test('planned trips are excluded from actual-only count', () {
      final trips = [
        actual('2025-01-05', '2025-01-07', id: 'a'), // 3 days, actual
        planned(
          '2025-01-15',
          '2025-01-17',
          id: 'b',
        ), // 3 days, planned — excluded
      ];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        3,
      );
    });

    test('planned trips are included when includeStatuses contains planned',
        () {
      final trips = [
        actual('2025-01-05', '2025-01-07', id: 'a'), // 3 days
        planned('2025-01-15', '2025-01-17', id: 'b'), // 3 days
      ];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
          includeStatuses: {TripStatus.actual, TripStatus.planned},
        ),
        6,
      );
    });

    test('empty trip list returns 0', () {
      expect(
        DayCounter.countDaysInWindow(
          trips: [],
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        0,
      );
    });

    test('window spanning a DST spring-forward still counts every day', () {
      // EN: Regression test. In a North American DST timezone, local midnights
      //     on Jan 1 and Mar 16 2025 are 74 days MINUS ONE HOUR apart (clocks
      //     spring forward Mar 9), so raw difference().inDays truncates to 73
      //     and the count silently loses a day. The engine anchors day math in
      //     UTC, so this must be exactly 75 (31 Jan + 28 Feb + 16 Mar) in every
      //     timezone the test machine could be in.
      // FR: Test de régression. Dans un fuseau nord-américain à heure d'été,
      //     les minuits locaux du 1er jan. et du 16 mars 2025 sont séparés de
      //     74 jours MOINS UNE HEURE (avance d'heure le 9 mars), donc
      //     difference().inDays brut tronque à 73 et le compte perd un jour en
      //     silence. Le moteur ancre le calcul des jours en UTC, donc ceci doit
      //     valoir exactement 75 (31 jan. + 28 fév. + 16 mars) quel que soit le
      //     fuseau de la machine de test.
      final trips = [actual('2025-01-01', '2025-12-31')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 3, 16),
        ),
        75,
      );
    });

    test('trip spanning entire window counts all window days', () {
      // EN: Trip covers the whole year; window is just January = 31 days.
      // FR: Le séjour couvre toute l'année ; la fenêtre est seulement janvier = 31 jours.
      final trips = [actual('2025-01-01', '2025-12-31')];
      expect(
        DayCounter.countDaysInWindow(
          trips: trips,
          windowStart: DateTime(2025, 1, 1),
          windowEnd: DateTime(2025, 1, 31),
        ),
        31,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // countDaysInLastDays
  // ---------------------------------------------------------------------------

  group('countDaysInLastDays', () {
    test('counts only days within rolling window ending today', () {
      // EN: Today is Jan 31. Window is Jan 1 – Jan 31 (31 days).
      //     Trip is Jan 15 – Feb 05; only Jan 15–31 (17 days) overlap.
      // FR: Aujourd'hui est le 31 jan. Fenêtre : 1–31 jan. (31 jours).
      //     Séjour 15 jan. – 5 fév. ; seuls les 15–31 jan. (17 jours) chevauchent.
      final today = DateTime(2025, 1, 31);
      final trips = [actual('2025-01-15', '2025-02-05')];
      expect(
        DayCounter.countDaysInLastDays(
          trips: trips,
          days: 31,
          today: today,
        ),
        17,
      );
    });

    test('days: 1 means today only', () {
      final today = DateTime(2025, 6, 15);
      final trips = [actual('2025-06-15', '2025-06-15')]; // exactly today
      expect(
        DayCounter.countDaysInLastDays(trips: trips, days: 1, today: today),
        1,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // countDaysInCalendarYear
  // ---------------------------------------------------------------------------

  group('countDaysInCalendarYear', () {
    test('counts days across a full year correctly', () {
      final trips = [
        actual('2024-01-10', '2024-01-20', id: 'a'), // 11 days
        actual('2024-11-01', '2024-11-15', id: 'b'), // 15 days
      ];
      expect(
        DayCounter.countDaysInCalendarYear(trips: trips, year: 2024),
        26,
      );
    });

    test('trip spanning year boundary counts only days in that year', () {
      // EN: Trip is Dec 25 2024 – Jan 05 2025. For year 2024 that's Dec 25–31 = 7 days.
      // FR: Séjour 25 déc. 2024 – 5 jan. 2025. Pour 2024 : 25–31 déc. = 7 jours.
      final trips = [actual('2024-12-25', '2025-01-05')];
      expect(
        DayCounter.countDaysInCalendarYear(trips: trips, year: 2024),
        7,
      );
      // EN: For year 2025 that's Jan 1–5 = 5 days.
      // FR: Pour 2025 : 1–5 jan. = 5 jours.
      expect(
        DayCounter.countDaysInCalendarYear(trips: trips, year: 2025),
        5,
      );
    });

    test('no trips in that year returns 0', () {
      final trips = [actual('2023-06-01', '2023-06-15')];
      expect(
        DayCounter.countDaysInCalendarYear(trips: trips, year: 2024),
        0,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Trip.daysInUS — belt-and-suspenders check that the model is consistent
  // ---------------------------------------------------------------------------

  group('Trip.daysInUS', () {
    test('same-day trip is 1 day', () {
      expect(actual('2025-03-01', '2025-03-01').daysInUS, 1);
    });

    test('two-day trip is 2 days', () {
      expect(actual('2025-03-01', '2025-03-02').daysInUS, 2);
    });

    test('week-long trip is 7 days', () {
      expect(actual('2025-03-01', '2025-03-07').daysInUS, 7);
    });

    test('trip spanning a DST spring-forward does not lose a day', () {
      // EN: Regression test — Mar 8–10 2025 crosses the North American clock
      //     change; must be 3 days in every timezone (see daysInUS comment).
      // FR: Test de régression — le 8–10 mars 2025 traverse le changement
      //     d'heure nord-américain ; doit valoir 3 jours dans tout fuseau
      //     (voir le commentaire de daysInUS).
      expect(actual('2025-03-08', '2025-03-10').daysInUS, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // substantialPresence — the IRS Substantial Presence figure as pure arithmetic
  // ---------------------------------------------------------------------------

  group('substantialPresence', () {
    test('weights three years as current + 1/3 prior + 1/6 second prior', () {
      // EN: 120 days in 2025, 90 in 2024 (leap year), 60 in 2023.
      //     Figure = 120 + 90/3 + 60/6 = 120 + 30 + 10 = 160 exactly.
      //     In sixths: 6*120 + 2*90 + 60 = 960.
      // FR: 120 jours en 2025, 90 en 2024 (année bissextile), 60 en 2023.
      //     Valeur = 120 + 90/3 + 60/6 = 120 + 30 + 10 = 160 exactement.
      //     En sixièmes : 6*120 + 2*90 + 60 = 960.
      final trips = [
        actual('2025-01-01', '2025-04-30', id: 'a'), // 120 days / jours
        actual('2024-01-01', '2024-03-30', id: 'b'), // 90 days / jours
        actual('2023-06-01', '2023-07-30', id: 'c'), // 60 days / jours
      ];
      final result = DayCounter.substantialPresence(
        trips: trips,
        asOf: DateTime(2025, 12, 31),
      );
      expect(result.currentYearDays, 120);
      expect(result.priorYearDays, 90);
      expect(result.secondPriorYearDays, 60);
      expect(result.totalSixths, 960);
      expect(result.total, 160.0);
    });

    test('current year counts only days up to and including asOf', () {
      // EN: Trip runs Jun 25 – Jul 10 but asOf is Jun 30 → only Jun 25–30 = 6 days.
      // FR: Séjour du 25 juin au 10 juil. mais asOf est le 30 juin → seulement
      //     25–30 juin = 6 jours.
      final trips = [actual('2025-06-25', '2025-07-10')];
      final result = DayCounter.substantialPresence(
        trips: trips,
        asOf: DateTime(2025, 6, 30),
      );
      expect(result.currentYearDays, 6);
      expect(result.priorYearDays, 0);
      expect(result.secondPriorYearDays, 0);
    });

    test('fractional weights stay exact in sixths (no float drift)', () {
      // EN: A single day in the prior year is worth exactly 1/3 — stored as
      //     2 sixths, never 0.3333… rounded somewhere.
      // FR: Un seul jour dans l'année précédente vaut exactement 1/3 — stocké
      //     comme 2 sixièmes, jamais 0,3333… arrondi quelque part.
      final trips = [actual('2024-05-01', '2024-05-01')];
      final result = DayCounter.substantialPresence(
        trips: trips,
        asOf: DateTime(2025, 12, 31),
      );
      expect(result.totalSixths, 2);
      expect(result.total, closeTo(1 / 3, 1e-12));
    });

    test('planned trips are excluded by default', () {
      final trips = [
        actual('2025-01-01', '2025-01-10', id: 'a'), // 10 days / jours
        planned('2025-03-01', '2025-03-10', id: 'b'), // excluded / exclu
      ];
      final result = DayCounter.substantialPresence(
        trips: trips,
        asOf: DateTime(2025, 12, 31),
      );
      expect(result.currentYearDays, 10);
    });

    test('no trips at all yields an all-zero result', () {
      final result = DayCounter.substantialPresence(
        trips: [],
        asOf: DateTime(2025, 12, 31),
      );
      expect(result.currentYearDays, 0);
      expect(result.priorYearDays, 0);
      expect(result.secondPriorYearDays, 0);
      expect(result.totalSixths, 0);
      expect(result.total, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // firstDateReachingThreshold — the projected date a user-defined target is hit
  // ---------------------------------------------------------------------------

  group('firstDateReachingThreshold', () {
    test('continuous presence reaches the 75th day on day 75', () {
      // EN: In the US every day from Jan 1 2025. Day #75 of 2025 is Mar 16
      //     (31 Jan + 28 Feb + 16 Mar).
      // FR: Aux États-Unis chaque jour depuis le 1er jan. 2025. Le 75e jour de
      //     2025 est le 16 mars (31 jan. + 28 fév. + 16 mars).
      final trips = [actual('2025-01-01', '2025-12-31')];
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: 75,
          windowDays: 1095,
          from: DateTime(2025, 1, 1),
        ),
        DateTime(2025, 3, 16),
      );
    });

    test('past actual days plus a planned trip project the reach date', () {
      // EN: 31 actual days in Dec 2024, planned Feb 1 – Apr 30 2025, window 365.
      //     31 + 28 (all of Feb) = 59 by Feb 28; the 16th planned day of March
      //     brings the total to 75 → Mar 16 2025.
      // FR: 31 jours réels en déc. 2024, séjour planifié 1 fév. – 30 avr. 2025,
      //     fenêtre 365. 31 + 28 (tout février) = 59 au 28 fév. ; le 16e jour
      //     planifié de mars porte le total à 75 → 16 mars 2025.
      final trips = [
        actual('2024-12-01', '2024-12-31', id: 'a'),
        planned('2025-02-01', '2025-04-30', id: 'b'),
      ];
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: 75,
          windowDays: 365,
          from: DateTime(2025, 1, 15),
        ),
        DateTime(2025, 3, 16),
      );
    });

    test('already at or above the threshold returns the from date itself', () {
      final trips = [actual('2025-01-01', '2025-01-10')];
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: 5,
          windowDays: 365,
          from: DateTime(2025, 1, 20),
        ),
        DateTime(2025, 1, 20),
      );
    });

    test('threshold never reached returns null', () {
      final trips = [actual('2025-01-01', '2025-01-10')];
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: 100,
          windowDays: 365,
          from: DateTime(2025, 1, 1),
        ),
        isNull,
      );
    });

    test('days aging out of a short rolling window prevent the threshold', () {
      // EN: Window 30 days, threshold 15. Trip A (10 days, early Jan) has fully
      //     aged out of the window before trip B (6 days, mid Feb) begins, so the
      //     count never reaches 15 at any single date.
      // FR: Fenêtre de 30 jours, seuil de 15. Le séjour A (10 jours, début jan.)
      //     est entièrement sorti de la fenêtre avant que le séjour B (6 jours,
      //     mi-fév.) commence, donc le total n'atteint jamais 15 à aucune date.
      final trips = [
        actual('2025-01-01', '2025-01-10', id: 'a'),
        actual('2025-02-15', '2025-02-20', id: 'b'),
      ];
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: 15,
          windowDays: 30,
          from: DateTime(2025, 1, 1),
        ),
        isNull,
      );
    });

    test('threshold larger than the window is impossible and returns null', () {
      final trips = [actual('2025-01-01', '2025-12-31')];
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: 31,
          windowDays: 30,
          from: DateTime(2025, 1, 1),
        ),
        isNull,
      );
    });

    test('out-of-cap inputs are rejected, never silently accepted', () {
      // EN: Hard input caps are a security boundary (PLAN.md) — a crafted or
      //     corrupted value must throw, not schedule pathological work.
      // FR: Les plafonds stricts sont une frontière de sécurité (PLAN.md) — une
      //     valeur forgée ou corrompue doit lancer une exception, pas déclencher
      //     un travail pathologique.
      final trips = [actual('2025-01-01', '2025-01-10')];
      DateTime? call({required int thresholdDays, required int windowDays}) {
        return DayCounter.firstDateReachingThreshold(
          trips: trips,
          thresholdDays: thresholdDays,
          windowDays: windowDays,
          from: DateTime(2025, 1, 1),
        );
      }

      expect(
        () => call(thresholdDays: 0, windowDays: 365),
        throwsArgumentError,
      );
      expect(
        () => call(thresholdDays: 75, windowDays: 0),
        throwsArgumentError,
      );
      expect(
        () => call(
          thresholdDays: InputLimits.maxThresholdDays + 1,
          windowDays: 365,
        ),
        throwsArgumentError,
      );
      expect(
        () => call(
          thresholdDays: 75,
          windowDays: InputLimits.maxWindowDays + 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
