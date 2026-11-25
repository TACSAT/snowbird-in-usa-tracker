// EN: Tests for the range counts (FR-6) and the what-if projection (FR-3). These
//     numbers describe days that may not happen, so what each one includes is pinned.
// FR: Tests des comptes par période (FR-6) et de la projection hypothétique (FR-3).
//     Ces nombres décrivent des jours qui n'auront peut-être pas lieu ; ce que chacun
//     inclut est donc verrouillé.

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/projection.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

Trip _trip(String a, String? d, [TripStatus s = TripStatus.actual]) => Trip(
      id: '$a$d${s.name}',
      arrivalDate: DateTime.parse(a),
      departureDate: d == null ? null : DateTime.parse(d),
      status: s,
    );

void main() {
  const planned = TripStatus.planned;
  final today = DateTime(2026, 11, 24, 15);

  group('RangeCount', () {
    RangeCount count(List<Trip> trips, String start, String end) =>
        RangeCount.compute(
          trips: trips,
          start: DateTime.parse(start),
          end: DateTime.parse(end),
          today: today,
        );

    test('actual stops at today; the second figure adds planned days', () {
      final r = count(
        [
          _trip('2026-01-01', '2026-01-31'),
          _trip('2026-12-01', '2026-12-10', planned),
        ],
        '2026-01-01',
        '2026-12-31',
      );
      expect(r.actual, 31);
      expect(r.withPlanned, 41);
    });

    test('both range ends are inclusive', () {
      final r = count(
        [_trip('2026-01-01', '2026-01-31')],
        '2026-01-10',
        '2026-01-10',
      );
      expect((r.actual, r.withPlanned), (1, 1));
    });

    test('an expected departure adds its future days to the second figure', () {
      final r = count(
        [_trip('2026-11-20', '2026-11-30')],
        '2026-11-01',
        '2026-11-30',
      );
      expect((r.actual, r.withPlanned), (5, 11));
    });

    test('an open stay is assumed to continue to the end of the range', () {
      final r = count([_trip('2026-11-20', null)], '2026-11-01', '2026-11-30');
      expect((r.actual, r.withPlanned), (5, 11));
    });

    test('a range entirely in the past ignores the future', () {
      final r = count([_trip('2026-11-20', null)], '2025-01-01', '2025-12-31');
      expect((r.actual, r.withPlanned), (0, 0));
    });

    test('a planned trip overlapping an actual one never double-counts', () {
      final r = count(
        [
          _trip('2026-11-01', '2026-11-10'),
          _trip('2026-11-10', '2026-11-12', planned),
        ],
        '2026-11-01',
        '2026-11-30',
      );
      expect((r.actual, r.withPlanned), (10, 12));
    });
  });

  group('WhatIf', () {
    WhatIf project(List<Trip> trips, String a, String d) => WhatIf.compute(
          trips: trips,
          arrival: DateTime.parse(a),
          departure: DateTime.parse(d),
        );

    test('compares the departure date with and without the trip', () {
      final r = project(
        [_trip('2026-01-01', '2026-03-31')],
        '2026-12-01',
        '2026-12-20',
      );
      expect(r.asOf, DateTime(2026, 12, 20));
      expect((r.last365.without, r.last365.including), (90, 110));
      expect(r.years.single.year, 2026);
      expect(r.years.single.days.without, 90);
      expect(r.years.single.days.including, 110);
      expect(r.sptWithout.currentYearDays, 90);
      expect(r.sptIncluding.currentYearDays, 110);
    });

    test('a trip across New Year reports each year through its own end', () {
      final r = project(const [], '2026-12-22', '2027-01-05');
      expect([for (final y in r.years) y.year], [2026, 2027]);
      expect(r.years[0].through, DateTime(2026, 12, 31));
      expect(r.years[0].days.including, 10);
      expect(r.years[1].through, DateTime(2027, 1, 5));
      expect(r.years[1].days.including, 5);
      expect(r.sptIncluding.totalSixths, 6 * 5 + 2 * 10);
    });

    test('other planned trips count on both sides', () {
      final r = project(
        [_trip('2026-12-01', '2026-12-05', planned)],
        '2026-12-10',
        '2026-12-12',
      );
      expect((r.last365.without, r.last365.including), (5, 8));
    });

    test('planned days after the departure date are not counted yet', () {
      final r = project(
        [_trip('2026-12-20', '2026-12-30', planned)],
        '2026-12-10',
        '2026-12-12',
      );
      expect(r.years.single.days.without, 0);
      expect(r.years.single.days.including, 3);
    });

    test('days already covered by another trip add nothing', () {
      final r = project(
        [_trip('2026-12-01', '2026-12-31', planned)],
        '2026-12-10',
        '2026-12-12',
      );
      expect(r.last365.without, r.last365.including);
    });

    test('a departure before the arrival is refused', () {
      expect(
        () => project(const [], '2026-12-10', '2026-12-09'),
        throwsArgumentError,
      );
    });

    test('never mutates the trips it is given', () {
      final trips =
          List<Trip>.unmodifiable([_trip('2026-01-01', '2026-01-02')]);
      project(trips, '2026-12-10', '2026-12-11');
      expect(trips, hasLength(1));
    });
  });

  test('past planned trips are found, so the user can settle them', () {
    final found = stalePlannedTrips(
      [
        _trip('2026-10-01', '2026-10-05', planned),
        _trip('2026-11-20', '2026-11-24', planned),
        _trip('2026-12-01', '2026-12-05', planned),
        _trip('2026-10-10', '2026-10-12'),
      ],
      today,
    );
    expect(found.single.arrivalDate, DateTime(2026, 10, 1));
  });
}
