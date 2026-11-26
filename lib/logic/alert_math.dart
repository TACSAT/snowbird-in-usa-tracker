// EN: Alert arithmetic by place (FEA-1, WRK-10). The original US alerts count
//     "any part of the day" presence with DayCounter, whose rules and tests
//     are unchanged. An alert counted at the end of the day, or counting days
//     worked, needs the ledger instead; this file does that search with the
//     SAME rules as DayCounter.firstDateReachingThreshold: actual and planned
//     stays, an open stay assumed to continue, and (crossingOnly) the first date
//     the count rises to the target rather than a date already past it. A test
//     proves both give the same date for any-part presence.
// FR: Calcul des alertes par lieu (FEA-1, WRK-10). Les alertes d'origine aux
//     États-Unis comptent la présence « toute partie du jour » avec DayCounter,
//     dont les règles et les tests sont inchangés. Une alerte comptée en fin de
//     journée, ou comptant les jours travaillés, demande plutôt le registre ; ce
//     fichier fait cette recherche avec les MÊMES règles que
//     DayCounter.firstDateReachingThreshold : séjours réels et planifiés, un
//     séjour ouvert supposé se poursuivre, et (crossingOnly) la première date où
//     le compte monte jusqu'à la cible plutôt qu'une date déjà dépassée. Un test
//     prouve que les deux donnent la même date pour la présence toute partie.

import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

const _both = {TripStatus.actual, TripStatus.planned};

abstract final class AlertMath {
  // EN: The first date, from [from] on, where the count over a rolling window
  //     of [windowDays] reaches [thresholdDays]; null if never within the
  //     search horizon (InputLimits.maxReachSearchDays).
  // FR: La première date, à partir de [from], où le compte sur une fenêtre
  //     glissante de [windowDays] atteint [thresholdDays] ; null si jamais dans
  //     l'horizon de recherche (InputLimits.maxReachSearchDays).
  static DateTime? firstDateReaching({
    required List<Trip> stays,
    List<DayVisit> visits = const [],
    required Place place,
    required CountingConvention convention,
    required AlertMeasure measure,
    required int thresholdDays,
    required int windowDays,
    required DateTime from,
    bool crossingOnly = false,
  }) {
    if (thresholdDays > windowDays) return null;
    final start = DateTime(from.year, from.month, from.day);
    final horizon = DateTime(
      start.year,
      start.month,
      start.day + InputLimits.maxReachSearchDays,
    );
    final first = DateTime(start.year, start.month, start.day - windowDays);
    // EN: "Today" set to the horizon makes the ledger project: an open stay
    //     continues, as DayCounter assumes for alerts.
    // FR: « Aujourd'hui » placé à l'horizon fait projeter le registre : un
    //     séjour ouvert se poursuit, comme le suppose DayCounter pour les
    //     alertes.
    final ledger = PresenceLedger.build(
      stays: stays,
      visits: visits,
      from: first,
      to: horizon,
      today: horizon,
      convention: convention,
      includeStatuses: _both,
    );
    final hits = _hits(ledger, place, measure);
    // EN: prefix[i] = number of hits in days[0..i-1], so any window is O(1).
    // FR: prefix[i] = nombre de jours comptés dans days[0..i-1], afin que
    //     toute fenêtre coûte O(1).
    final prefix = List<int>.filled(hits.length + 1, 0);
    for (var i = 0; i < hits.length; i++) {
      prefix[i + 1] = prefix[i] + (hits[i] ? 1 : 0);
    }
    int countEndingAt(int i) {
      final lo = i - windowDays + 1;
      return prefix[i + 1] - prefix[lo < 0 ? 0 : lo];
    }

    final startIndex = windowDays;
    var wasReached =
        crossingOnly && countEndingAt(startIndex - 1) >= thresholdDays;
    for (var i = startIndex; i < hits.length; i++) {
      if (countEndingAt(i) < thresholdDays) {
        wasReached = false;
      } else if (!wasReached) {
        return DateTime(start.year, start.month, start.day + (i - startIndex));
      }
    }
    return null;
  }

  // EN: The count over the last [windowDays] ending [today], actual and
  //     planned, as the alerts list shows "reached" today.
  // FR: Le compte sur les [windowDays] derniers jours se terminant [today],
  //     réels et planifiés, comme la liste des alertes montre « atteint »
  //     aujourd'hui.
  static int countInLastDays({
    required List<Trip> stays,
    List<DayVisit> visits = const [],
    required Place place,
    required CountingConvention convention,
    required AlertMeasure measure,
    required int windowDays,
    required DateTime today,
  }) {
    final end = DateTime(today.year, today.month, today.day);
    final ledger = PresenceLedger.build(
      stays: stays,
      visits: visits,
      from: DateTime(end.year, end.month, end.day - (windowDays - 1)),
      to: end,
      today: end,
      convention: convention,
      includeStatuses: _both,
    );
    return _hits(ledger, place, measure).where((h) => h).length;
  }

  static List<bool> _hits(
    PresenceLedger ledger,
    Place place,
    AlertMeasure measure,
  ) =>
      [
        for (final day in ledger.days)
          (measure == AlertMeasure.present ? day.places : day.worked)
              .any(place.contains),
      ];
}
