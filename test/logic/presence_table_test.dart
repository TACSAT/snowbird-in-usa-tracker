// EN: Tests for the Days present table data (REQUIREMENTS-places.md section 9):
//     which rows appear, in what order, with which figures, and that every
//     figure equals the engine's.
// FR: Tests des données du tableau des jours de présence
//     (REQUIREMENTS-places.md, section 9) : quelles lignes apparaissent, dans
//     quel ordre, avec quels chiffres, et que chaque chiffre égale celui du
//     moteur.

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_table.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

final _today = DateTime(2026, 11, 26);
final _on = Place.parse('CA-ON');
final _qc = Place.parse('CA-QC');
final _fl = Place.parse('US-FL');

var _n = 0;
Trip _stay(
  Place place,
  DateTime a,
  DateTime? d, {
  TripStatus status = TripStatus.actual,
}) =>
    Trip(
      id: 's${_n++}',
      arrivalDate: a,
      departureDate: d,
      status: status,
      place: place,
    );

PresenceTable _table(
  List<Trip> stays, {
  List<TrackedPlace>? tracked,
  HomeBase? home,
  List<DayVisit> visits = const [],
}) =>
    PresenceTable.build(
      stays: stays,
      visits: visits,
      home: home,
      tracked: tracked,
      today: _today,
    );

void main() {
  test('a US-only user sees one row and the SPT, as simple as before', () {
    final stays = [
      _stay(Place.unitedStates, DateTime(2026, 1, 5), DateTime(2026, 3, 31)),
    ];
    final t = _table(stays);
    expect(t.entries, hasLength(1));
    final us = t.entries.single;
    expect(us.row.place, Place.unitedStates);
    expect(us.row.recorded.thisYear, 86);
    expect(us.expandable, isFalse, reason: 'no region to show');
    expect(us.regionNotRecorded.thisYear, 86);
    expect(
      t.spt?.totalSixths,
      DayCounter.substantialPresence(trips: stays, asOf: _today).totalSixths,
    );
    expect(t.hasCrossingDays, isFalse);
    expect(t.now, isNull);
    expect(t.conventions, {CountingConvention.anyPart});
  });

  test('automatic rows: countries in catalogue order, regions by days', () {
    final t = _table([
      _stay(_fl, DateTime(2026, 1, 5), DateTime(2026, 3, 31)),
      _stay(_on, DateTime(2026, 3, 31), DateTime(2026, 6, 1)),
      _stay(_qc, DateTime(2026, 6, 1), DateTime(2026, 6, 10)),
      _stay(Place.canada, DateTime(2026, 6, 10), DateTime(2026, 6, 20)),
      _stay(Place.mexico, DateTime(2026, 11, 1), null),
    ]);
    expect(
      t.entries.map((e) => e.row.place),
      [Place.canada, Place.unitedStates, Place.mexico],
    );
    final canada = t.entries.first;
    expect(canada.expandable, isTrue);
    expect(canada.regions.map((r) => r.place), [_on, _qc]);
    expect(canada.regionNotRecorded.thisYear, 11);
    expect(canada.row.recorded.thisYear, 82, reason: "31 March to 20 June");
    expect(t.hasCrossingDays, isTrue, reason: '31 March: Florida and Ontario');
    expect(t.now?.stay.place, Place.mexico);
    expect(t.now?.days, 26);
  });

  test('planned stays never appear in the table', () {
    final t = _table([
      _stay(
        Place.mexico,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 9),
        status: TripStatus.planned,
      ),
    ]);
    expect(t.entries, isEmpty);
    expect(t.spt, isNull);
  });

  test('a chosen list keeps its order, hides empty rows unless pinned', () {
    final stays = [_stay(_on, DateTime(2026, 2, 1), DateTime(2026, 2, 10))];
    final t = _table(
      stays,
      tracked: [
        const TrackedPlace(Place.mexico),
        const TrackedPlace(Place.unitedStates, pinned: true),
        TrackedPlace(_on),
      ],
    );
    expect(t.entries.map((e) => e.row.place), [Place.unitedStates, _on]);
    expect(t.entries.first.row.recorded.isZero, isTrue);
    expect(t.spt, isNotNull, reason: 'the US is tracked, even at zero');
    final ontario = t.entries.last;
    expect(ontario.regions, isEmpty, reason: 'a region tracked on its own');
    expect(ontario.row.recorded.thisYear, 10);
  });

  test('no SPT without the United States as an entry (TBL-7)', () {
    final t = _table(
      [_stay(_fl, DateTime(2026, 2, 1), DateTime(2026, 2, 10))],
      tracked: [TrackedPlace(_fl)],
    );
    expect(t.entries.single.row.place, _fl);
    expect(t.spt, isNull);
  });

  test('each place uses its own convention (CNT-1)', () {
    final stays = [
      _stay(_on, DateTime(2026, 1, 1), DateTime(2026, 1, 10)),
      _stay(Place.parse('US-NY'), DateTime(2026, 1, 10), DateTime(2026, 1, 15)),
      _stay(_qc, DateTime(2026, 1, 15), DateTime(2026, 1, 20)),
    ];
    final t = _table(
      stays,
      tracked: [
        const TrackedPlace(Place.canada),
        const TrackedPlace(
          Place.unitedStates,
          convention: CountingConvention.endOfDay,
        ),
      ],
    );
    expect(t.entries[0].row.recorded.thisYear, 16);
    expect(t.entries[1].row.recorded.thisYear, 5);
    expect(t.conventions, CountingConvention.values.toSet());
  });

  test('home base: assumed days apart, home country shown with none recorded',
      () {
    final home = HomeBase([HomePeriod(place: _on, from: DateTime(2020))]);
    final t = _table(
      [_stay(_fl, DateTime(2026, 1, 5), DateTime(2026, 3, 31))],
      home: home,
    );
    expect(
      t.entries.map((e) => e.row.place),
      [Place.canada, Place.unitedStates],
    );
    final canada = t.entries.first;
    expect(canada.row.recorded.isZero, isTrue);
    final year = _today.difference(DateTime(2026)).inDays + 1;
    expect(canada.row.assumed.thisYear, year - 86 + 2);
    expect(canada.regions.single.place, _on);
    expect(canada.regions.single.assumed.thisYear, canada.row.assumed.thisYear);
    expect(t.notRecorded.isZero, isTrue);
  });

  test('without home base, unrecorded days are their own row', () {
    final t = _table([_stay(_fl, DateTime(2026, 1, 5), DateTime(2026, 3, 31))]);
    expect(
      t.notRecorded.thisYear,
      _today.difference(DateTime(2026)).inDays + 1 - 86,
    );
  });

  test('day visits count, by any part of the day', () {
    final t = _table(
      [_stay(_on, DateTime(2026, 1, 1), null)],
      visits: [DayVisit(id: 'v', date: DateTime(2026, 4, 2), place: _fl)],
    );
    final us = t.entries.firstWhere((e) => e.row.place == Place.unitedStates);
    expect(us.row.recorded.thisYear, 1);
    expect(t.spt?.currentYearDays, 1);
  });

  test('figures equal the ledger for every entry and window', () {
    final stays = [
      _stay(_fl, DateTime(2025, 11, 1), DateTime(2026, 3, 31)),
      _stay(_on, DateTime(2026, 3, 31), DateTime(2026, 8, 1)),
      _stay(Place.mexico, DateTime(2026, 8, 1), null),
    ];
    final ledger = PresenceLedger.build(
      stays: stays,
      from: DateTime(2025, 11, 27),
      to: _today,
      today: _today,
    );
    for (final entry in _table(stays).entries) {
      final p = entry.row.place;
      expect(
        entry.row.recorded.thisYear,
        ledger.daysIn(p, start: DateTime(2026)),
      );
      expect(entry.row.recorded.last365, ledger.daysIn(p));
    }
  });
}
