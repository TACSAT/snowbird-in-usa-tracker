// EN: Pure arithmetic for "how many days in this period?" (FR-6) and "what would my
//     counts be if I took this trip?" (FR-3). Built entirely on DayCounter: nothing
//     here counts a day itself, so the rules cannot drift. No storage, no verdicts.
// FR: Arithmétique pure pour « combien de jours dans cette période ? » (FR-6) et
//     « que deviendraient mes comptes si je faisais ce séjour ? » (FR-3). Bâtie
//     entièrement sur DayCounter : rien ici ne compte un jour, donc les règles ne
//     peuvent diverger. Aucun stockage, aucun verdict.

import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
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

// EN: Ranges and the what-if BY PLACE (FEA-2, FEA-3, WRK-10). The classes above
//     keep their original United States meaning and tests; these report every
//     chosen place under its own counting convention, from PresenceLedger.
// FR: Plages et hypothèse PAR LIEU (FEA-2, FEA-3, WRK-10). Les classes
//     ci-dessus gardent leur sens d'origine (États-Unis) et leurs tests ;
//     celles-ci rendent compte de chaque lieu choisi selon sa propre convention
//     de comptage, à partir de PresenceLedger.

// EN: One place's figures for a range: actual days, days including planned
//     stays, and actual days worked.
// FR: Les chiffres d'un lieu pour une plage : jours réels, jours en incluant
//     les séjours planifiés, et jours travaillés réels.
class PlaceRangeCount {
  final Place place;
  final CountingConvention convention;
  final int actual;
  final int withPlanned;
  final int worked;

  const PlaceRangeCount._(
    this.place,
    this.convention,
    this.actual,
    this.withPlanned,
    this.worked,
  );

  // EN: [tracked] null means the countries with any day in the range, actual
  //     or planned, in catalogue order: the same idea as the automatic table.
  // FR: [tracked] null signifie les pays ayant au moins un jour dans la plage,
  //     réel ou planifié, dans l'ordre du catalogue : la même idée que le
  //     tableau automatique.
  static List<PlaceRangeCount> compute({
    required List<Trip> stays,
    List<DayVisit> visits = const [],
    List<TrackedPlace>? tracked,
    required DateTime start,
    required DateTime end,
    required DateTime today,
    Place? fallback,
  }) {
    final now = _dateOnly(today);
    final last = _dateOnly(end);
    final actual = <CountingConvention, PresenceLedger>{};
    final planned = <CountingConvention, PresenceLedger>{};
    PresenceLedger ledger(CountingConvention c, {required bool withPlanned}) =>
        (withPlanned ? planned : actual)[c] ??= PresenceLedger.build(
          stays: stays,
          visits: visits,
          from: start,
          to: end,
          today: withPlanned && last.isAfter(now) ? last : now,
          convention: c,
          includeStatuses: withPlanned ? _both : const {TripStatus.actual},
        );

    final seen =
        ledger(CountingConvention.anyPart, withPlanned: true).recordedPlaces;
    // EN: A copy, so the fallback below never writes into the caller's list.
    // FR: Une copie, afin que le repli ci-dessous n'écrive jamais dans la
    //     liste de l'appelant.
    final list = [
      ...tracked ??
          [
            for (final country in {
              ...PlaceCatalog.countries,
              ...([for (final p in seen) p.country]
                ..sort((a, b) => a.code.compareTo(b.code))),
            })
              if (seen.any(country.contains)) TrackedPlace(country),
          ],
    ];
    // EN: A period with no day anywhere still answers "0 days" for the place
    //     the user is most likely asking about, rather than showing nothing.
    // FR: Une période sans aucun jour répond quand même « 0 jour » pour le
    //     lieu sur lequel l'utilisateur s'interroge le plus probablement,
    //     plutôt que de ne rien montrer.
    if (list.isEmpty && fallback != null) list.add(TrackedPlace(fallback));
    return [
      for (final item in list)
        PlaceRangeCount._(
          item.place,
          item.convention,
          ledger(item.convention, withPlanned: false).daysIn(item.place),
          ledger(item.convention, withPlanned: true).daysIn(item.place),
          ledger(item.convention, withPlanned: false).workedIn(item.place),
        ),
    ];
  }
}

// EN: One affected place in a what-if: per calendar year and the last 365 days,
//     without and with the possible trip.
// FR: Un lieu concerné par une hypothèse : par année civile et sur les 365
//     derniers jours, sans et avec le voyage envisagé.
class PlaceComparison {
  final Place place;
  final CountingConvention convention;
  final List<YearComparison> years;
  final Comparison last365;

  const PlaceComparison(this.place, this.convention, this.years, this.last365);
}

class PlaceWhatIf {
  final DateTime asOf;
  final Place tripPlace;
  final List<PlaceComparison> places;

  // EN: Only when the trip is in the United States (TBL-7's rule, here too).
  // FR: Seulement quand le voyage est aux États-Unis (la règle de TBL-7, ici
  //     aussi).
  final (SubstantialPresenceResult, SubstantialPresenceResult)? spt;

  const PlaceWhatIf._(this.asOf, this.tripPlace, this.places, this.spt);

  // EN: The affected places are the tracked ones that contain the trip's place
  //     (a trip to Florida affects "United States" and "Florida"), or else the
  //     trip's own country. As in WhatIf, counts run to the trip's last day,
  //     with an open stay assumed to continue until then.
  // FR: Les lieux concernés sont les lieux suivis qui contiennent le lieu du
  //     voyage (un voyage en Floride concerne « États-Unis » et « Floride »),
  //     sinon le pays du voyage. Comme dans WhatIf, les comptes vont jusqu'au
  //     dernier jour du voyage, un séjour ouvert étant supposé durer jusque-là.
  factory PlaceWhatIf.compute({
    required List<Trip> stays,
    List<DayVisit> visits = const [],
    required DateTime arrival,
    required DateTime departure,
    required Place place,
    List<TrackedPlace>? tracked,
  }) {
    final from = _dateOnly(arrival);
    final asOf = _dateOnly(departure);
    if (asOf.isBefore(from)) {
      throw ArgumentError.value(departure, 'departure', 'precedes arrival');
    }
    final trip = Trip(
      id: 'what-if',
      arrivalDate: from,
      departureDate: asOf,
      status: TripStatus.planned,
      place: place,
    );
    final affected = [
      for (final t in tracked ?? const <TrackedPlace>[])
        if (t.place.contains(place)) t,
    ];
    if (affected.isEmpty) affected.add(TrackedPlace(place.country));

    final rangeStart = DateTime(from.year);
    final last365Start = DateTime(asOf.year, asOf.month, asOf.day - 364);
    final first = rangeStart.isBefore(last365Start) ? rangeStart : last365Start;
    PresenceLedger ledger(List<Trip> list, CountingConvention c) =>
        PresenceLedger.build(
          stays: list,
          visits: visits,
          from: first,
          to: asOf,
          today: asOf,
          convention: c,
          includeStatuses: _both,
        );

    final comparisons = <PlaceComparison>[];
    for (final item in affected) {
      final without = ledger(stays, item.convention);
      final including = ledger([...stays, trip], item.convention);
      Comparison compare(DateTime start, DateTime end) => Comparison(
            without.daysIn(item.place, start: start, end: end),
            including.daysIn(item.place, start: start, end: end),
          );
      comparisons.add(
        PlaceComparison(
          item.place,
          item.convention,
          [
            for (var year = from.year; year <= asOf.year; year++)
              () {
                final through =
                    year == asOf.year ? asOf : DateTime(year, 12, 31);
                return YearComparison(
                  year,
                  through,
                  compare(DateTime(year), through),
                );
              }(),
          ],
          compare(last365Start, asOf),
        ),
      );
    }

    final counted = [...stays, for (final v in visits) v.asStay()];
    SubstantialPresenceResult spt(List<Trip> list) =>
        DayCounter.substantialPresence(
          trips: list,
          asOf: asOf,
          includeStatuses: _both,
        );
    return PlaceWhatIf._(
      asOf,
      place,
      comparisons,
      Place.unitedStates.contains(place)
          ? (spt(counted), spt([...counted, trip]))
          : null,
    );
  }
}
