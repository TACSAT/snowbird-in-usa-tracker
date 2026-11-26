// EN: The Days present table (REQUIREMENTS-places.md section 9), as plain data.
//     It replaces the two US figures on the main screen: one entry per tracked
//     place, with this calendar year and the last 365 days, regions under their
//     country, and separate rows for "region not recorded", "assumed at home"
//     and "not recorded". Every number comes from PresenceLedger (or, for the
//     Substantial Presence figure, DayCounter), so the table can never disagree
//     with the engine that the tests check. No widget code here: the screen only
//     lays this out.
// FR: Le tableau des jours de présence (REQUIREMENTS-places.md, section 9), sous
//     forme de simples données. Il remplace les deux chiffres des États-Unis de
//     l'écran principal : une entrée par lieu suivi, avec l'année civile en
//     cours et les 365 derniers jours, les régions sous leur pays, et des lignes
//     séparées pour « région non précisée », « présumés au domicile » et « non
//     enregistrés ». Chaque nombre vient de PresenceLedger (ou, pour le chiffre
//     de présence substantielle, de DayCounter) ; le tableau ne peut donc jamais
//     contredire le moteur que les tests vérifient. Aucun code d'interface ici :
//     l'écran ne fait que mettre ceci en page.

import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

// EN: One figure over the table's two windows.
// FR: Un chiffre sur les deux fenêtres du tableau.
class WindowFigures {
  final int thisYear;
  final int last365;

  const WindowFigures(this.thisYear, this.last365);

  bool get isZero => thisYear == 0 && last365 == 0;
}

// EN: One place's line: recorded days, and assumed days at home kept apart
//     (HOM-2), under one counting convention.
// FR: La ligne d'un lieu : jours enregistrés, et jours présumés au domicile
//     gardés à part (HOM-2), selon une convention de comptage.
class PlaceRow {
  final Place place;
  final CountingConvention convention;
  final WindowFigures recorded;
  final WindowFigures assumed;

  // EN: Days worked there (TBL-12): shown as a second line only when work is
  //     on, never summed with days present.
  // FR: Jours travaillés sur place (TBL-12) : montrés en seconde ligne
  //     seulement si le travail est activé, jamais additionnés aux jours de
  //     présence.
  final WindowFigures worked;

  const PlaceRow({
    required this.place,
    required this.convention,
    required this.recorded,
    required this.assumed,
    this.worked = const WindowFigures(0, 0),
  });

  bool get isEmpty => recorded.isZero && assumed.isZero;
}

// EN: A table entry: a country with its regions (TBL-2), or a region tracked on
//     its own (TBL-3, then [regions] is empty).
// FR: Une entrée du tableau : un pays avec ses régions (TBL-2), ou une région
//     suivie seule (TBL-3, [regions] est alors vide).
class TableEntry {
  final PlaceRow row;
  final List<PlaceRow> regions;
  final WindowFigures regionNotRecorded;

  const TableEntry({
    required this.row,
    this.regions = const [],
    this.regionNotRecorded = const WindowFigures(0, 0),
  });

  // EN: Only a country with at least one region's days can expand; one whose
  //     days are all "region not recorded" has nothing to show beneath it.
  // FR: Seul un pays ayant des jours dans au moins une région peut se déplier ;
  //     un pays dont tous les jours sont « région non précisée » n'a rien à
  //     montrer dessous.
  bool get expandable => regions.isNotEmpty;
}

// EN: "Now: Yukon, 12 days" (TBL-9): the ongoing stay and how long it has lasted.
// FR: « Actuellement : Yukon, 12 jours » (TBL-9) : le séjour en cours et sa durée.
class CurrentPlace {
  final Trip stay;
  final int days;

  const CurrentPlace(this.stay, this.days);
}

class PresenceTable {
  final DateTime today;
  final List<TableEntry> entries;
  final WindowFigures notRecorded;
  final bool hasCrossingDays;
  final CurrentPlace? now;

  // EN: The Substantial Presence figure: present only when the United States
  //     itself is a table entry (TBL-7).
  // FR: Le chiffre de présence substantielle : présent seulement quand les
  //     États-Unis eux-mêmes sont une entrée du tableau (TBL-7).
  final SubstantialPresenceResult? spt;

  const PresenceTable._({
    required this.today,
    required this.entries,
    required this.notRecorded,
    required this.hasCrossingDays,
    required this.now,
    required this.spt,
  });

  // EN: The conventions the visible rows use, so the screen labels each one
  //     (CNT-1: always labelled).
  // FR: Les conventions utilisées par les lignes visibles, afin que l'écran les
  //     étiquette toutes (CNT-1 : toujours étiquetées).
  Set<CountingConvention> get conventions => {
        for (final entry in entries) entry.row.convention,
      };

  // EN: Builds the table for [today].
  //     - [tracked] null means automatic: every country with recorded or
  //       assumed days in either window, in catalogue order (TBL-4: suggested
  //       at first from places with recorded days). A user with one country
  //       therefore sees one row, as simple as before.
  //     - With a list, its order is kept, and an entry with no days in either
  //       window is hidden unless pinned (TBL-5).
  //     Only ACTUAL stays and visits count: this is a table of what happened.
  // FR: Construit le tableau pour [today].
  //     - [tracked] null signifie automatique : chaque pays ayant des jours
  //       enregistrés ou présumés dans l'une des fenêtres, dans l'ordre du
  //       catalogue (TBL-4 : suggérés d'abord à partir des lieux ayant des jours
  //       enregistrés). Un utilisateur d'un seul pays voit donc une seule ligne,
  //       aussi simple qu'avant.
  //     - Avec une liste, son ordre est conservé, et une entrée sans aucun jour
  //       dans les deux fenêtres est masquée sauf si elle est épinglée (TBL-5).
  //     Seuls les séjours et visites RÉELS comptent : c'est un tableau de ce qui
  //     a eu lieu.
  factory PresenceTable.build({
    required List<Trip> stays,
    List<DayVisit> visits = const [],
    HomeBase? home,
    List<TrackedPlace>? tracked,
    required DateTime today,
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final yearStart = DateTime(day.year);
    final last365Start = DateTime(day.year, day.month, day.day - 364);
    final from = yearStart.isBefore(last365Start) ? yearStart : last365Start;

    final ledgers = <CountingConvention, PresenceLedger>{};
    PresenceLedger ledger(CountingConvention c) =>
        ledgers[c] ??= PresenceLedger.build(
          stays: stays,
          visits: visits,
          home: home,
          from: from,
          to: day,
          today: day,
          convention: c,
        );

    WindowFigures figures(int Function({DateTime? start, DateTime? end}) f) =>
        WindowFigures(f(start: yearStart), f(start: last365Start));

    PlaceRow rowFor(Place place, CountingConvention convention) {
      final l = ledger(convention);
      return PlaceRow(
        place: place,
        convention: convention,
        recorded: figures(
          ({start, end}) => l.daysIn(place, start: start, end: end),
        ),
        assumed: figures(
          ({start, end}) => l.assumedIn(place, start: start, end: end),
        ),
        worked: figures(
          ({start, end}) => l.workedIn(place, start: start, end: end),
        ),
      );
    }

    final any = ledger(CountingConvention.anyPart);
    final homePlaces = {
      if (home != null && !home.isOff)
        for (final period in home.periods) period.place,
    };
    final seen = {...any.recordedPlaces, ...homePlaces};

    final list = tracked ??
        [
          for (final country in {
            ...PlaceCatalog.countries,
            ...([for (final p in seen) p.country]
              ..sort((a, b) => a.code.compareTo(b.code))),
          })
            if (seen.any(country.contains)) TrackedPlace(country),
        ];

    final entries = <TableEntry>[];
    for (final item in list) {
      final row = rowFor(item.place, item.convention);
      if (row.isEmpty && !item.pinned) continue;
      if (!item.place.isCountry) {
        entries.add(TableEntry(row: row));
        continue;
      }
      final l = ledger(item.convention);
      final regionCodes = {
        for (final p in [...l.recordedPlaces, ...homePlaces])
          if (!p.isCountry && item.place.contains(p)) p,
      };
      final regions = [
        for (final region in regionCodes) rowFor(region, item.convention),
      ]
        ..removeWhere((r) => r.isEmpty)
        // EN: Most days first, so the places that matter lead; ties by code
        //     for a stable order.
        // FR: Le plus de jours d'abord, afin que les lieux importants viennent
        //     en tête ; à égalité, par code pour un ordre stable.
        ..sort((a, b) {
          final byDays = b.recorded.last365.compareTo(a.recorded.last365);
          return byDays != 0 ? byDays : a.place.code.compareTo(b.place.code);
        });
      entries.add(
        TableEntry(
          row: row,
          regions: regions,
          regionNotRecorded: figures(
            ({start, end}) =>
                l.regionNotRecorded(item.place, start: start, end: end),
          ),
        ),
      );
    }

    final usTracked = entries.any((e) => e.row.place == Place.unitedStates);
    final counted = [...stays, for (final v in visits) v.asStay()];

    Trip? ongoing;
    for (final stay in stays) {
      if (stay.status == TripStatus.actual &&
          stay.departureDate == null &&
          !stay.arrivalDate.isAfter(day) &&
          (ongoing == null || stay.arrivalDate.isAfter(ongoing.arrivalDate))) {
        ongoing = stay;
      }
    }

    return PresenceTable._(
      today: day,
      entries: entries,
      notRecorded: figures(any.notRecorded),
      hasCrossingDays: any.crossingDays(start: from) > 0,
      now: ongoing == null
          ? null
          : CurrentPlace(ongoing, ongoing.daysPresent(day)),
      spt: usTracked
          ? DayCounter.substantialPresence(trips: counted, asOf: day)
          : null,
    );
  }
}
