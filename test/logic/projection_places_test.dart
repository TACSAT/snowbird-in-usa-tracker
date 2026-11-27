// EN: Tests for ranges and the what-if by place (FEA-2, FEA-3, WRK-10). A US
//     what-if must give exactly what the original WhatIf gives; other places
//     are reported under their own convention; the SPT appears only for a trip
//     in the United States.
// FR: Tests des plages et de l'hypothèse par lieu (FEA-2, FEA-3, WRK-10). Une
//     hypothèse aux États-Unis doit donner exactement ce que donne le WhatIf
//     d'origine ; les autres lieux sont rapportés selon leur propre convention ;
//     le critère de présence substantielle n'apparaît que pour un voyage aux
//     États-Unis.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/logic/projection.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';

final _today = DateTime(2026, 11, 26);
final _on = Place.parse('CA-ON');
final _fl = Place.parse('US-FL');

var _n = 0;
Trip _stay(
  Place place,
  DateTime a,
  DateTime? d, {
  TripStatus status = TripStatus.actual,
  WorkPlan? work,
}) =>
    Trip(
      id: 'p${_n++}',
      arrivalDate: a,
      departureDate: d,
      status: status,
      place: place,
      work: work,
    );

void main() {
  test('a US what-if equals the original WhatIf, over random histories', () {
    final r = Random(9);
    for (var n = 0; n < 100; n++) {
      final stays = <Trip>[];
      var day = DateTime(2025, 1, 1 + r.nextInt(200));
      for (var i = 0; i < 8 && day.isBefore(_today); i++) {
        final end = DateTime(day.year, day.month, day.day + r.nextInt(50));
        final open = i == 7 && r.nextBool();
        stays.add(
          _stay(
            Place.unitedStates,
            day,
            open ? null : (end.isAfter(_today) ? _today : end),
          ),
        );
        if (open) break;
        day = DateTime(end.year, end.month, end.day + r.nextInt(40));
      }
      final arrival = DateTime(2026, 12, 1 + r.nextInt(60));
      final departure =
          DateTime(arrival.year, arrival.month, arrival.day + r.nextInt(90));
      final old = WhatIf.compute(
        trips: stays,
        arrival: arrival,
        departure: departure,
      );
      final mine = PlaceWhatIf.compute(
        stays: stays,
        arrival: arrival,
        departure: departure,
        place: Place.unitedStates,
      );
      final us = mine.places.single;
      expect(us.place, Place.unitedStates);
      expect(
        [for (final y in us.years) (y.year, y.days.without, y.days.including)],
        [for (final y in old.years) (y.year, y.days.without, y.days.including)],
        reason: 'history $n',
      );
      expect(
        (us.last365.without, us.last365.including),
        (old.last365.without, old.last365.including),
      );
      expect(mine.spt!.$1.totalSixths, old.sptWithout.totalSixths);
      expect(mine.spt!.$2.totalSixths, old.sptIncluding.totalSixths);
    }
  });

  test('a trip to Florida affects the US and Florida, not Canada', () {
    final r = PlaceWhatIf.compute(
      stays: [_stay(_on, DateTime(2026, 1, 1), DateTime(2026, 6, 30))],
      arrival: DateTime(2027, 1, 5),
      departure: DateTime(2027, 3, 31),
      place: _fl,
      tracked: const [
        TrackedPlace(Place.canada),
        TrackedPlace(Place.unitedStates),
      ],
    );
    expect(r.places.map((p) => p.place), [Place.unitedStates]);
    expect(r.places.single.years.single.days.including, 86);
    expect(r.spt, isNotNull);
    final both = PlaceWhatIf.compute(
      stays: const [],
      arrival: DateTime(2027, 1, 5),
      departure: DateTime(2027, 3, 31),
      place: _fl,
      tracked: [const TrackedPlace(Place.unitedStates), TrackedPlace(_fl)],
    );
    expect(both.places.map((p) => p.place), [Place.unitedStates, _fl]);
  });

  test('a trip to Ontario: Canada by its convention, and no SPT', () {
    final r = PlaceWhatIf.compute(
      stays: const [],
      arrival: DateTime(2027, 6, 1),
      departure: DateTime(2027, 6, 10),
      place: _on,
      tracked: const [
        TrackedPlace(Place.canada, convention: CountingConvention.endOfDay),
      ],
    );
    expect(r.places.single.place, Place.canada);
    expect(r.places.single.years.single.days.including, 9);
    expect(r.spt, isNull);
    final untracked = PlaceWhatIf.compute(
      stays: const [],
      arrival: DateTime(2027, 6, 1),
      departure: DateTime(2027, 6, 10),
      place: _on,
    );
    expect(untracked.places.single.place, Place.canada);
    expect(untracked.places.single.years.single.days.including, 10);
  });

  group('ranges by place', () {
    final stays = [
      _stay(_fl, DateTime(2026, 1, 5), DateTime(2026, 3, 31)),
      _stay(
        _on,
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
        work: WorkPlan(weekdays: {1, 2, 3, 4, 5}),
      ),
      _stay(
        Place.mexico,
        DateTime(2026, 12, 1),
        DateTime(2026, 12, 20),
        status: TripStatus.planned,
      ),
    ];

    test('automatic: countries with days, actual and with planned, worked', () {
      final r = PlaceRangeCount.compute(
        stays: stays,
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        today: _today,
      );
      expect(
        r.map((c) => c.place),
        [Place.canada, Place.unitedStates, Place.mexico],
      );
      expect((r[0].actual, r[0].withPlanned, r[0].worked), (31, 31, 23));
      expect((r[1].actual, r[1].withPlanned), (86, 86));
      expect((r[2].actual, r[2].withPlanned), (0, 20));
    });

    test('a chosen place uses its convention', () {
      final r = PlaceRangeCount.compute(
        stays: stays,
        tracked: const [
          TrackedPlace(
            Place.unitedStates,
            convention: CountingConvention.endOfDay,
          ),
        ],
        start: DateTime(2026),
        end: DateTime(2026, 12, 31),
        today: _today,
      );
      expect(r.single.actual, 85);
    });

    test('an empty period answers 0 for the fallback, even with none chosen',
        () {
      for (final tracked in [null, const <TrackedPlace>[]]) {
        final r = PlaceRangeCount.compute(
          stays: stays,
          tracked: tracked,
          start: DateTime(2020),
          end: DateTime(2020, 12, 31),
          today: _today,
          fallback: Place.unitedStates,
        );
        expect(r.single.place, Place.unitedStates);
        expect(r.single.actual, 0);
      }
    });
  });
}
