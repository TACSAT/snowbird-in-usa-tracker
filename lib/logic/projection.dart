// EN: Pure arithmetic for "how many days in this period?" (FR-6) and "what would my
//     counts be if I took this trip?" (FR-3). Built entirely on DayCounter: nothing
//     here counts a day itself, so the rules cannot drift. No storage, no verdicts.
// FR: Arithmétique pure pour « combien de jours dans cette période ? » (FR-6) et
//     « que deviendraient mes comptes si je faisais ce séjour ? » (FR-3). Bâtie
//     entièrement sur DayCounter : rien ici ne compte un jour, donc les règles ne
//     peuvent diverger. Aucun stockage, aucun verdict.

import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

const _both = {TripStatus.actual, TripStatus.planned};

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class RangeCount {
  // EN: Days actually spent in the range, up to today.
  // FR: Jours réellement passés dans la période, jusqu'à aujourd'hui.
  final int actual;

  // EN: The same plus planned days, expected future days of a current trip, and, for
  //     an open trip, every day to the end of the range.
  // FR: Les mêmes plus les jours planifiés, les jours futurs prévus d'un séjour en
  //     cours et, pour un séjour ouvert, chaque jour jusqu'à la fin de la période.
  final int withPlanned;

  const RangeCount._(this.actual, this.withPlanned);

  factory RangeCount.compute({
    required List<Trip> trips,
    required DateTime start,
    required DateTime end,
    required DateTime today,
  }) {
    final now = _dateOnly(today);
    final last = _dateOnly(end);
    return RangeCount._(
      DayCounter.countDaysInWindow(
        trips: trips,
        windowStart: start,
        windowEnd: end,
        asOf: now,
      ),
      DayCounter.countDaysInWindow(
        trips: trips,
        windowStart: start,
        windowEnd: end,
        asOf: last.isAfter(now) ? last : now,
        includeStatuses: _both,
      ),
    );
  }
}

// EN: One figure, without and including the hypothetical trip.
// FR: Un nombre, sans et avec le séjour hypothétique.
class Comparison {
  final int without;
  final int including;
  const Comparison(this.without, this.including);
}

class YearComparison {
  final int year;

  // EN: Last day counted: the year's end, or the departure date in its own year.
  // FR: Dernier jour compté : la fin de l'année, ou la date de départ dans la sienne.
  final DateTime through;
  final Comparison days;
  const YearComparison(this.year, this.through, this.days);
}

// EN: The counts as they would stand on the hypothetical departure date, which is
//     when the trip's effect is complete. Actual and planned trips count on both
//     sides, so the difference is exactly what this trip would add.
// FR: Les comptes tels qu'ils seraient à la date de départ hypothétique, quand l'effet
//     du séjour est complet. Les séjours réels et planifiés comptent des deux côtés :
//     la différence est donc exactement ce que ce séjour ajouterait.
class WhatIf {
  final DateTime asOf;
  final List<YearComparison> years;
  final Comparison last365;
  final SubstantialPresenceResult sptWithout;
  final SubstantialPresenceResult sptIncluding;

  const WhatIf._({
    required this.asOf,
    required this.years,
    required this.last365,
    required this.sptWithout,
    required this.sptIncluding,
  });

  factory WhatIf.compute({
    required List<Trip> trips,
    required DateTime arrival,
    required DateTime departure,
  }) {
    final from = _dateOnly(arrival);
    final asOf = _dateOnly(departure);
    if (asOf.isBefore(from)) {
      throw ArgumentError.value(departure, 'departure', 'precedes arrival');
    }
    // EN: A plain in-memory trip; it has a fixed ID because it is never stored.
    // FR: Un simple séjour en mémoire ; son ID est fixe car il n'est jamais stocké.
    final including = [
      ...trips,
      Trip(
        id: 'what-if',
        arrivalDate: from,
        departureDate: asOf,
        status: TripStatus.planned,
      ),
    ];
    Comparison compare(int Function(List<Trip>) count) =>
        Comparison(count(trips), count(including));
    SubstantialPresenceResult spt(List<Trip> list) =>
        DayCounter.substantialPresence(
          trips: list,
          asOf: asOf,
          includeStatuses: _both,
        );

    return WhatIf._(
      asOf: asOf,
      years: [
        for (var year = from.year; year <= asOf.year; year++)
          () {
            final through = year == asOf.year ? asOf : DateTime(year, 12, 31);
            return YearComparison(
              year,
              through,
              compare(
                (list) => DayCounter.countDaysInWindow(
                  trips: list,
                  windowStart: DateTime(year),
                  windowEnd: through,
                  asOf: asOf,
                  includeStatuses: _both,
                ),
              ),
            );
          }(),
      ],
      last365: compare(
        (list) => DayCounter.countDaysInLastDays(
          trips: list,
          days: 365,
          today: asOf,
          includeStatuses: _both,
        ),
      ),
      sptWithout: spt(trips),
      sptIncluding: spt(including),
    );
  }
}

// EN: Planned trips whose dates are entirely past. They still count in projections;
//     only the user knows whether they happened, so they are disclosed, not dropped.
// FR: Séjours planifiés dont les dates sont entièrement passées. Ils comptent encore
//     dans les projections ; seul l'utilisateur sait s'ils ont eu lieu, donc ils sont
//     signalés plutôt qu'écartés.
List<Trip> stalePlannedTrips(List<Trip> trips, DateTime today) => [
      for (final t in trips)
        if (t.status == TripStatus.planned &&
            (t.departureDate?.isBefore(_dateOnly(today)) ?? false))
          t,
    ];
