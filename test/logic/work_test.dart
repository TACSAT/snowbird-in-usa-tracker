// EN: Tests for days worked (REQUIREMENTS-places.md section 7 and section 18):
//     the weekday pattern and single-day corrections, storage, that no worked
//     day exists outside its stay, and that days worked never exceed days
//     present for the same place and dates, over random histories.
// FR: Tests des jours travaillés (REQUIREMENTS-places.md, sections 7 et 18) :
//     le motif de jours et les corrections de jours isolés, le stockage,
//     l'absence de jour travaillé hors de son séjour, et le fait que les jours
//     travaillés ne dépassent jamais les jours de présence pour un même lieu et
//     les mêmes dates, sur des historiques aléatoires.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';

final _today = DateTime(2026, 11, 26);
final _on = Place.parse('CA-ON');
final _qc = Place.parse('CA-QC');
final _weekdays = {1, 2, 3, 4, 5};

PresenceLedger _ledger(
  List<Trip> stays, {
  List<DayVisit> visits = const [],
  CountingConvention convention = CountingConvention.anyPart,
  DateTime? from,
}) =>
    PresenceLedger.build(
      stays: stays,
      visits: visits,
      from: from ?? DateTime(2026),
      to: DateTime(2026, 12, 31),
      today: _today,
      convention: convention,
    );

void main() {
  group('WorkPlan', () {
    test('a pattern, a day off and an extra day', () {
      // EN: 2 March 2026 is a Monday.
      // FR: Le 2 mars 2026 est un lundi.
      var plan = WorkPlan(weekdays: _weekdays);
      expect(plan.isWorked(DateTime(2026, 3, 2)), isTrue);
      expect(plan.isWorked(DateTime(2026, 3, 7)), isFalse);
      plan = plan.toggled(DateTime(2026, 3, 2)).toggled(DateTime(2026, 3, 7));
      expect(plan.isWorked(DateTime(2026, 3, 2)), isFalse);
      expect(plan.isWorked(DateTime(2026, 3, 7)), isTrue);
      plan = plan.toggled(DateTime(2026, 3, 2)).toggled(DateTime(2026, 3, 7));
      expect(plan.added, isEmpty);
      expect(plan.removed, isEmpty);
    });

    test('corrections survive a change of pattern', () {
      final plan = WorkPlan(weekdays: _weekdays)
          .toggled(DateTime(2026, 3, 7))
          .withWeekdays({1});
      expect(plan.isWorked(DateTime(2026, 3, 7)), isTrue);
      expect(plan.isWorked(DateTime(2026, 3, 3)), isFalse);
    });

    test('JSON round trip, and bad data is refused', () {
      final plan = WorkPlan(weekdays: _weekdays)
          .toggled(DateTime(2026, 3, 2))
          .toggled(DateTime(2026, 3, 7));
      final back = WorkPlan.fromJson(plan.toJson());
      expect(back.weekdays, _weekdays);
      expect(back.added, {DateTime(2026, 3, 7)});
      expect(back.removed, {DateTime(2026, 3, 2)});
      expect(
        () => WorkPlan.fromJson({
          'weekdays': [8],
        }),
        throwsFormatException,
      );
      expect(
        () => WorkPlan.fromJson({
          'weekdays': <int>[],
          'added': ['soon'],
        }),
        throwsFormatException,
      );
    });
  });

  group('stays and visits', () {
    test('a stay keeps its plan in storage; older data has none', () {
      final stay = Trip.create(
        arrivalDate: DateTime(2026, 3, 1),
        departureDate: DateTime(2026, 3, 31),
        status: TripStatus.actual,
        place: _on,
        work: WorkPlan(weekdays: _weekdays),
      );
      final back = Trip.fromJson(stay.toJson());
      expect(back.work?.weekdays, _weekdays);
      final old = Trip.fromJson({...stay.toJson()}..remove('work'));
      expect(old.work, isNull);
      expect(
        Trip.create(
          arrivalDate: DateTime(2026),
          departureDate: DateTime(2026),
          status: TripStatus.actual,
          work: WorkPlan(),
        ).toJson().containsKey('work'),
        isFalse,
      );
    });

    test('changing the dates never invents a worked day outside (WRK-3)', () {
      final stay = Trip.create(
        arrivalDate: DateTime(2026, 3, 1),
        departureDate: DateTime(2026, 3, 31),
        status: TripStatus.actual,
        place: _on,
        work: WorkPlan(weekdays: const {}).toggled(DateTime(2026, 3, 28)),
      );
      final shorter = stay.copyWith(departureDate: DateTime(2026, 3, 20));
      expect(shorter.work, isNull, reason: 'the only worked day fell outside');
      final longer = shorter.copyWith(departureDate: DateTime(2026, 3, 31));
      expect(
        _ledger([longer]).workedIn(_on),
        0,
        reason: 'the dropped day does not come back',
      );
    });

    test('presence and work are separate figures; work is never inferred', () {
      final l = _ledger([
        Trip(
          id: 'a',
          arrivalDate: DateTime(2026, 3, 1),
          departureDate: DateTime(2026, 3, 31),
          status: TripStatus.actual,
          place: _on,
          work: WorkPlan(weekdays: _weekdays),
        ),
        Trip(
          id: 'b',
          arrivalDate: DateTime(2026, 4, 1),
          departureDate: DateTime(2026, 4, 30),
          status: TripStatus.actual,
          place: _on,
        ),
      ]);
      expect(l.daysIn(_on), 61);
      expect(l.workedIn(_on), 22, reason: 'weekdays of March 2026');
    });

    test('a worked day visit, and one date worked in two places (WRK-6)', () {
      final l = _ledger(
        [
          Trip(
            id: 'a',
            arrivalDate: DateTime(2026, 3, 1),
            departureDate: DateTime(2026, 3, 31),
            status: TripStatus.actual,
            place: _on,
            work: WorkPlan(weekdays: _weekdays),
          ),
        ],
        visits: [
          DayVisit(
            id: 'v',
            date: DateTime(2026, 3, 2),
            place: _qc,
            worked: true,
          ),
          DayVisit(id: 'w', date: DateTime(2026, 3, 3), place: _qc),
        ],
      );
      expect(l.workedIn(_qc), 1);
      expect(l.workedIn(_on), 22);
      expect(l.workedIn(Place.canada), 22, reason: 'once per date in Canada');
      expect(l.daysIn(_qc), 2);
    });

    test('an ongoing stay works only up to today', () {
      final l = _ledger([
        Trip(
          id: 'a',
          arrivalDate: DateTime(2026, 11, 23),
          departureDate: null,
          status: TripStatus.actual,
          place: _on,
          work: WorkPlan(weekdays: {1, 2, 3, 4, 5, 6, 7}),
        ),
      ]);
      expect(l.workedIn(_on), 4);
    });
  });

  test('days worked never exceed days present, any part (section 18)', () {
    final r = Random(11);
    final leaves = [_on, _qc, Place.canada, Place.unitedStates, Place.mexico];
    for (var n = 0; n < 300; n++) {
      final stays = <Trip>[];
      var day = DateTime(2025, 1, 1 + r.nextInt(200));
      for (var i = 0; i < 20 && day.isBefore(_today); i++) {
        final end = DateTime(day.year, day.month, day.day + r.nextInt(40));
        var plan = WorkPlan(
          weekdays: {
            for (var d = 1; d <= 7; d++)
              if (r.nextBool()) d,
          },
        );
        for (var k = r.nextInt(5); k > 0; k--) {
          plan = plan.toggled(
            DateTime(day.year, day.month, day.day + r.nextInt(80) - 20),
          );
        }
        stays.add(
          Trip.create(
            arrivalDate: day,
            departureDate: end,
            status: TripStatus.actual,
            place: leaves[r.nextInt(leaves.length)],
            work: plan,
          ),
        );
        day = DateTime(
          end.year,
          end.month,
          end.day + r.nextInt(3) * r.nextInt(9),
        );
      }
      final visits = [
        for (var k = r.nextInt(6); k > 0; k--)
          DayVisit(
            id: 'v$k',
            date: DateTime(2025, 1, 1 + r.nextInt(690)),
            place: leaves[r.nextInt(leaves.length)],
            worked: r.nextBool(),
          ),
      ];
      final l = _ledger(stays, visits: visits, from: DateTime(2025));
      for (final p in {...leaves, Place.canada}) {
        expect(
          l.workedIn(p),
          lessThanOrEqualTo(l.daysIn(p)),
          reason: '${p.code}, history $n',
        );
      }
      for (final d in l.days) {
        for (final w in d.worked) {
          expect(d.places.contains(w), isTrue, reason: '${d.date}');
        }
      }
    }
  });
}
