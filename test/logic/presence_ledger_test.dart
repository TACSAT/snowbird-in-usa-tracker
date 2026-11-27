// EN: Tests for the days-by-place engine (REQUIREMENTS-places.md sections 8 and
//     18). The worked examples of section 8 are checked exactly, under both
//     conventions; then the invariants of section 18 are checked over hundreds of
//     randomly generated histories, and the engine is compared with DayCounter
//     for every place, so the two can never drift apart.
// FR: Tests du moteur des jours par lieu (REQUIREMENTS-places.md, sections 8 et
//     18). Les exemples de la section 8 sont vérifiés exactement, selon les deux
//     conventions ; puis les invariants de la section 18 sont vérifiés sur des
//     centaines d'historiques générés au hasard, et le moteur est comparé à
//     DayCounter pour chaque lieu, afin que les deux ne puissent jamais diverger.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

final _today = DateTime(2026, 11, 26);
final _on = Place.parse('CA-ON');
final _qc = Place.parse('CA-QC');
final _ny = Place.parse('US-NY');

var _ids = 0;
Trip _stay(
  Place place,
  DateTime arrival,
  DateTime? departure, {
  TripStatus status = TripStatus.actual,
}) =>
    Trip(
      id: 'stay${_ids++}',
      arrivalDate: arrival,
      departureDate: departure,
      status: status,
      place: place,
    );

PresenceLedger _ledger(
  List<Trip> stays, {
  DateTime? from,
  DateTime? to,
  DateTime? today,
  CountingConvention convention = CountingConvention.anyPart,
  Set<TripStatus> statuses = const {TripStatus.actual},
  List<DayVisit> visits = const [],
  HomeBase? home,
}) =>
    PresenceLedger.build(
      stays: stays,
      from: from ?? DateTime(2026),
      to: to ?? DateTime(2026, 12, 31),
      today: today ?? _today,
      convention: convention,
      includeStatuses: statuses,
      visits: visits,
      home: home,
    );

void main() {
  group('worked example: Ontario, New York, Quebec', () {
    final stays = [
      _stay(_on, DateTime(2026, 1, 1), DateTime(2026, 1, 10)),
      _stay(_ny, DateTime(2026, 1, 10), DateTime(2026, 1, 15)),
      _stay(_qc, DateTime(2026, 1, 15), DateTime(2026, 1, 20)),
    ];
    final window = (from: DateTime(2026, 1, 1), to: DateTime(2026, 1, 20));

    test('any part of the day', () {
      final l = _ledger(stays, from: window.from, to: window.to);
      expect(l.daysIn(_on), 10);
      expect(l.daysIn(_qc), 6);
      expect(l.daysIn(Place.canada), 16);
      expect(l.daysIn(Place.unitedStates), 6);
      expect(l.crossingDays(), 2);
      expect(l.days, hasLength(20));
      expect(l.notRecorded(), 0);
    });

    test('end of day', () {
      final l = _ledger(
        stays,
        from: window.from,
        to: window.to,
        convention: CountingConvention.endOfDay,
      );
      expect(l.daysIn(_on), 9);
      expect(l.daysIn(_ny), 5);
      expect(l.daysIn(_qc), 5);
      expect(l.daysIn(Place.canada), 14);
      expect(l.crossingDays(), 0);
      expect(l.notRecorded(), 1, reason: '20 January: no next place');
    });
  });

  group('worked example: Ontario then Quebec', () {
    final stays = [
      _stay(_on, DateTime(2026, 6, 1), DateTime(2026, 6, 5)),
      _stay(_qc, DateTime(2026, 6, 5), DateTime(2026, 6, 8)),
    ];

    test('any part: Canada is 8, not 9', () {
      final l = _ledger(stays);
      expect(l.daysIn(_on), 5);
      expect(l.daysIn(_qc), 4);
      expect(l.daysIn(Place.canada), 8);
      expect(l.crossingDays(), 0, reason: 'a region change is no crossing');
    });

    test('end of day: Ontario 4, Quebec 3, 8 June not yet placed', () {
      final l = _ledger(stays, convention: CountingConvention.endOfDay);
      expect(l.daysIn(_on), 4);
      expect(l.daysIn(_qc), 3);
      expect(
        l.days.firstWhere((d) => d.date == DateTime(2026, 6, 8)).places,
        isEmpty,
      );
    });
  });

  group('rules', () {
    test('several places in one day, in order of arrival (STY-4)', () {
      final day = DateTime(2026, 3, 3);
      final l = _ledger([
        _stay(_qc, day, null),
        _stay(_on, DateTime(2026, 3, 1), day),
        _stay(_ny, day, day),
      ]);
      expect(
        l.days.firstWhere((d) => d.date == day).places,
        [_on, _qc, _ny],
        reason: 'arrival order, ties in list order',
      );
    });

    test('a same-day stop holds no night by end of day', () {
      final day = DateTime(2026, 3, 3);
      final l = _ledger(
        [
          _stay(_on, DateTime(2026, 3, 1), day),
          _stay(_ny, day, day),
          _stay(_qc, day, DateTime(2026, 3, 5)),
        ],
        convention: CountingConvention.endOfDay,
      );
      expect(l.daysIn(_ny), 0);
      expect(l.days.firstWhere((d) => d.date == day).places, [_qc]);
    });

    test('a date covered by several stays in one place counts once (CNT-3)',
        () {
      final l = _ledger([
        _stay(_on, DateTime(2026, 2, 1), DateTime(2026, 2, 10)),
        _stay(_on, DateTime(2026, 2, 5), DateTime(2026, 2, 12)),
        _stay(Place.canada, DateTime(2026, 2, 8), DateTime(2026, 2, 14)),
      ]);
      expect(l.daysIn(_on), 12);
      expect(l.daysIn(Place.canada), 14);
      expect(l.regionNotRecorded(Place.canada), 7);
      expect(
        l.days.firstWhere((d) => d.date == DateTime(2026, 2, 9)).places,
        [_on, Place.canada],
        reason: 'each place listed once per date, for the day-by-day ledger',
      );
    });

    test('an ongoing stay: today by any part, yesterday by end of day', () {
      final stays = [_stay(Place.mexico, DateTime(2026, 11, 20), null)];
      expect(_ledger(stays).daysIn(Place.mexico), 7);
      expect(
        _ledger(stays, convention: CountingConvention.endOfDay)
            .daysIn(Place.mexico),
        6,
      );
    });

    test('actual days stop at today; planned days are only counted if asked',
        () {
      final stays = [
        _stay(_on, DateTime(2026, 11, 20), DateTime(2026, 12, 10)),
        _stay(
          _ny,
          DateTime(2026, 12, 10),
          DateTime(2026, 12, 20),
          status: TripStatus.planned,
        ),
      ];
      expect(_ledger(stays).daysIn(_on), 7);
      expect(_ledger(stays).daysIn(_ny), 0);
      final both =
          _ledger(stays, statuses: {TripStatus.actual, TripStatus.planned});
      expect(both.daysIn(_ny), 11);
      expect(both.daysIn(_on), 7, reason: 'an actual stay never runs ahead');
    });

    test('end of day with an overlapping plan: the latest arrival wins', () {
      final l = _ledger(
        [
          _stay(
            _on,
            DateTime(2026, 12, 1),
            DateTime(2026, 12, 31),
            status: TripStatus.planned,
          ),
          _stay(
            _ny,
            DateTime(2026, 12, 10),
            DateTime(2026, 12, 15),
            status: TripStatus.planned,
          ),
        ],
        statuses: {TripStatus.planned},
        convention: CountingConvention.endOfDay,
      );
      expect(l.daysIn(_ny), 5);
      expect(l.daysIn(_on), 25);
      expect(l.days.every((d) => d.places.length <= 1), isTrue);
    });

    test('a day visit counts by any part only, and never as a stay', () {
      final visit = DayVisit(
        id: 'v',
        date: DateTime(2026, 2, 3),
        place: Place.parse('CA-QC'),
      );
      final stays = [_stay(_on, DateTime(2026, 2, 1), DateTime(2026, 2, 9))];
      final any = _ledger(stays, visits: [visit]);
      expect(any.daysIn(_qc), 1);
      expect(any.daysIn(_on), 9);
      expect(any.daysIn(Place.canada), 9);
      final eod = _ledger(
        stays,
        visits: [visit],
        convention: CountingConvention.endOfDay,
      );
      expect(eod.daysIn(_qc), 0);
    });

    test('a future actual visit and a planned visit do not count as actual',
        () {
      final l = _ledger(
        const [],
        visits: [
          DayVisit(id: 'a', date: DateTime(2026, 12, 1), place: _qc),
          DayVisit(
            id: 'b',
            date: DateTime(2026, 2, 1),
            place: _qc,
            status: TripStatus.planned,
          ),
        ],
      );
      expect(l.daysIn(_qc), 0);
    });

    test('home base: unrecorded past days are assumed, labelled apart', () {
      final home = HomeBase([
        HomePeriod(place: _on, from: DateTime(2026, 1, 1)),
        HomePeriod(place: _qc, from: DateTime(2026, 7, 1)),
      ]);
      final l = _ledger(
        [
          _stay(
            Place.parse('US-FL'),
            DateTime(2026, 1, 5),
            DateTime(2026, 3, 31),
          ),
        ],
        from: DateTime(2025, 12, 1),
        home: home,
      );
      expect(l.daysIn(_on), 0, reason: 'assumed days are not recorded days');
      // EN: 1 to 4 January, 1 April to 30 June, and the two crossing days
      //     (5 January and 31 March), when the user was home for part of the day.
      // FR: Du 1er au 4 janvier, du 1er avril au 30 juin, et les deux jours de
      //     passage (5 janvier et 31 mars), où l'utilisateur était chez lui une
      //     partie de la journée.
      expect(l.assumedIn(_on), 4 + 91 + 2);
      expect(l.daysIn(Place.parse('US-FL')), 86);
      expect(
        l.assumedIn(_qc),
        DateTime(2026, 11, 26).difference(DateTime(2026, 7, 1)).inDays + 1,
      );
      expect(l.assumedIn(Place.canada), l.assumedIn(_on) + l.assumedIn(_qc));
      expect(l.notRecorded(), 31, reason: 'December 2025 is before any home');
      expect(
        l.days.where((d) => d.date.isAfter(_today)).every(
              (d) => d.assumed == null && !d.notRecorded,
            ),
        isTrue,
        reason: 'the future is neither assumed nor unrecorded',
      );
    });

    group('home crossing days (owner decision 2026-11-26)', () {
      final home = HomeBase([HomePeriod(place: _on, from: DateTime(2025))]);
      Place? assumedOn(PresenceLedger l, DateTime d) =>
          l.days.firstWhere((x) => x.date == d).assumed;

      test('leaving and coming back count at home and away, by any part', () {
        final l = _ledger(
          [_stay(_ny, DateTime(2026, 2, 1), DateTime(2026, 2, 10))],
          home: home,
        );
        expect(assumedOn(l, DateTime(2026, 2, 1)), _on);
        expect(assumedOn(l, DateTime(2026, 2, 10)), _on);
        expect(assumedOn(l, DateTime(2026, 2, 5)), isNull);
        expect(l.daysIn(_ny), 10, reason: 'the away count is unchanged');
      });

      test('back-to-back stays: only the outer edges touch home', () {
        final l = _ledger(
          [
            _stay(_ny, DateTime(2026, 2, 1), DateTime(2026, 2, 10)),
            _stay(
              Place.parse('US-FL'),
              DateTime(2026, 2, 10),
              DateTime(2026, 2, 20),
            ),
          ],
          home: home,
        );
        expect(assumedOn(l, DateTime(2026, 2, 1)), _on);
        expect(assumedOn(l, DateTime(2026, 2, 10)), isNull);
        expect(assumedOn(l, DateTime(2026, 2, 20)), _on);
      });

      test('a stay inside the home place is not assumed a second time', () {
        final l = _ledger(
          [
            _stay(_on, DateTime(2026, 2, 1), DateTime(2026, 2, 3)),
            _stay(Place.canada, DateTime(2026, 3, 1), DateTime(2026, 3, 3)),
          ],
          home: home,
        );
        for (final d in [1, 3]) {
          expect(assumedOn(l, DateTime(2026, 2, d)), isNull);
          expect(assumedOn(l, DateTime(2026, 3, d)), isNull);
        }
      });

      test('an ongoing stay has no return day yet', () {
        final l = _ledger(
          [_stay(_ny, DateTime(2026, 11, 20), null)],
          home: home,
        );
        expect(assumedOn(l, DateTime(2026, 11, 20)), _on);
        expect(assumedOn(l, _today), isNull);
      });

      test('a stay leaving today returns home today', () {
        final l = _ledger(
          [_stay(_ny, DateTime(2026, 11, 20), _today)],
          home: home,
        );
        expect(assumedOn(l, _today), _on);
      });

      test('a crossing day uses the home of the day next to it', () {
        final moving = HomeBase([
          HomePeriod(place: _on, from: DateTime(2025)),
          HomePeriod(place: _qc, from: DateTime(2026, 2, 5)),
        ]);
        final l = _ledger(
          [_stay(_ny, DateTime(2026, 2, 1), DateTime(2026, 2, 10))],
          home: moving,
        );
        expect(assumedOn(l, DateTime(2026, 2, 1)), _on);
        expect(assumedOn(l, DateTime(2026, 2, 10)), _qc);
      });

      test('edges outside the range are seen correctly', () {
        final l = _ledger(
          [_stay(_ny, DateTime(2026, 2, 1), DateTime(2026, 2, 10))],
          from: DateTime(2026, 2, 1),
          to: DateTime(2026, 2, 10),
          home: home,
        );
        expect(l.assumedIn(_on), 2);
        final inner = _ledger(
          [
            _stay(_ny, DateTime(2026, 1, 31), DateTime(2026, 2, 1)),
            _stay(_ny, DateTime(2026, 2, 1), DateTime(2026, 2, 10)),
            _stay(_ny, DateTime(2026, 2, 10), DateTime(2026, 2, 11)),
          ],
          from: DateTime(2026, 2, 1),
          to: DateTime(2026, 2, 10),
          home: home,
        );
        expect(inner.assumedIn(_on), 0);
      });

      test('end of day is unchanged by the rule', () {
        final l = _ledger(
          [_stay(_ny, DateTime(2026, 2, 1), DateTime(2026, 2, 10))],
          home: home,
          convention: CountingConvention.endOfDay,
        );
        expect(assumedOn(l, DateTime(2026, 2, 1)), isNull);
        expect(assumedOn(l, DateTime(2026, 2, 10)), _on);
      });
    });

    test('without home base, unrecorded days stay "not recorded" (HOM-4)', () {
      final l = _ledger(
        [
          _stay(
            Place.unitedStates,
            DateTime(2026, 1, 1),
            DateTime(2026, 1, 31),
          ),
        ],
      );
      expect(l.assumedIn(Place.canada), 0);
      expect(
        l.notRecorded(),
        _today.difference(DateTime(2026, 2, 1)).inDays + 1,
      );
    });

    test('an unknown code is counted under its code and its country', () {
      final future = Place.parse('CA-XX');
      final l = _ledger(
        [_stay(future, DateTime(2026, 1, 1), DateTime(2026, 1, 3))],
      );
      expect(l.daysIn(future), 3);
      expect(l.daysIn(Place.canada), 3);
      expect(l.recordedPlaces, {future});
    });

    test('sub-ranges count only their own dates', () {
      final l = _ledger(
        [_stay(_on, DateTime(2025, 12, 20), DateTime(2026, 1, 10))],
        from: DateTime(2025),
      );
      expect(l.daysIn(_on, start: DateTime(2026)), 10);
      expect(l.daysIn(_on, end: DateTime(2025, 12, 31)), 12);
    });

    test('impossible ranges are refused', () {
      expect(
        () => _ledger(const [], from: DateTime(2026, 2), to: DateTime(2026)),
        throwsArgumentError,
      );
      expect(
        () => _ledger(const [], from: DateTime(1950), to: DateTime(2026)),
        throwsArgumentError,
      );
    });
  });

  group('invariants over random histories (section 18)', () {
    final leaves = [
      Place.canada,
      _on,
      _qc,
      Place.parse('CA-YT'),
      Place.unitedStates,
      _ny,
      Place.parse('US-FL'),
      Place.mexico,
      Place.parse('MX-SON'),
      Place.saintPierreAndMiquelon,
      Place.parse('PR'),
      Place.elsewhere,
    ];
    final countries = {for (final p in leaves) p.country};

    // EN: A valid actual history, as the repository would accept it: stays in
    //     sequence, sharing at most a boundary day, with gaps, same-day stops and
    //     perhaps an ongoing last stay; plus a few planned stays anywhere.
    // FR: Un historique réel valide, tel que le dépôt l'accepterait : des séjours
    //     à la suite, ne partageant au plus qu'un jour limite, avec des trous, des
    //     arrêts d'un jour et peut-être un dernier séjour en cours ; plus quelques
    //     séjours planifiés n'importe où.
    List<Trip> history(Random r) {
      final stays = <Trip>[];
      var day = DateTime(2023, 1, 1 + r.nextInt(400));
      final count = 1 + r.nextInt(40);
      for (var i = 0; i < count && day.isBefore(_today); i++) {
        final length = r.nextInt(5) == 0 ? 0 : r.nextInt(90);
        var end = DateTime(day.year, day.month, day.day + length);
        final open = i == count - 1 && r.nextBool();
        if (end.isAfter(_today)) end = _today;
        stays.add(
          _stay(leaves[r.nextInt(leaves.length)], day, open ? null : end),
        );
        if (open) break;
        final gap = r.nextInt(3) == 0 ? r.nextInt(30) : 0;
        day = DateTime(end.year, end.month, end.day + gap);
      }
      for (var i = r.nextInt(4); i > 0; i--) {
        final start = DateTime(2024, 1, 1 + r.nextInt(1200));
        stays.add(
          _stay(
            leaves[r.nextInt(leaves.length)],
            start,
            DateTime(start.year, start.month, start.day + r.nextInt(60)),
            status: TripStatus.planned,
          ),
        );
      }
      return stays..shuffle(r);
    }

    test('valid histories really are valid (the generator is honest)', () {
      final r = Random(1);
      for (var n = 0; n < 200; n++) {
        final actual =
            history(r).where((t) => t.status == TripStatus.actual).toList();
        for (final a in actual) {
          for (final b in actual) {
            if (a.id != b.id) expect(a.conflictsWith(b), isFalse);
          }
        }
      }
    });

    for (final statuses in [
      {TripStatus.actual},
      {TripStatus.actual, TripStatus.planned},
    ]) {
      test(
          'any part: bounds, regions and DayCounter agree (${statuses.length})',
          () {
        final r = Random(42);
        final from = DateTime(2023);
        final to = DateTime(2027, 6, 30);
        final calendar = to.difference(from).inDays + 1;
        for (var n = 0; n < 300; n++) {
          final stays = history(r);
          final l = _ledger(stays, from: from, to: to, statuses: statuses);
          for (final place in {...leaves, ...countries}) {
            final days = l.daysIn(place);
            expect(days, lessThanOrEqualTo(calendar));
            expect(
              days,
              DayCounter.countDaysInWindow(
                trips: stays,
                windowStart: from,
                windowEnd: to,
                asOf: _today,
                includeStatuses: statuses,
                place: place,
              ),
              reason: '${place.code} in history $n',
            );
          }
          for (final country in countries) {
            final regions =
                leaves.where((p) => !p.isCountry && country.contains(p));
            final total = l.daysIn(country);
            final sum = regions.fold<int>(0, (s, p) => s + l.daysIn(p)) +
                l.regionNotRecorded(country);
            for (final region in regions) {
              expect(total, greaterThanOrEqualTo(l.daysIn(region)));
            }
            expect(total, lessThanOrEqualTo(sum), reason: country.code);
          }
        }
      });
    }

    test('end of day: one place per date, and the calendar adds up', () {
      final r = Random(7);
      final from = DateTime(2023);
      final to = DateTime(2026, 12, 31);
      // EN: Dates that have ended: from the start through yesterday.
      // FR: Dates terminées : du début jusqu'à hier.
      final ended = _today.difference(from).inDays;
      for (var n = 0; n < 300; n++) {
        final stays = history(r);
        final home = r.nextBool()
            ? HomeBase([HomePeriod(place: _on, from: DateTime(2024))])
            : HomeBase.none;
        final eod = _ledger(
          stays,
          from: from,
          to: to,
          convention: CountingConvention.endOfDay,
          home: home,
        );
        final any = _ledger(stays, from: from, to: to, home: home);
        expect(eod.days.every((d) => d.places.length <= 1), isTrue);
        // EN: Count dates with a place, each once, whatever that place is.
        // FR: Compter les dates ayant un lieu, chacune une fois, quel qu'il soit.
        final placed = eod.days.where((d) => d.places.isNotEmpty).length;
        expect(
          placed + eod.assumedIn(_on) + eod.notRecorded(),
          ended,
          reason: 'history $n',
        );
        for (final place in {...leaves, ...countries}) {
          expect(eod.daysIn(place), lessThanOrEqualTo(any.daysIn(place)));
        }
        // EN: By any part, an assumed date never repeats a recorded place, and
        //     a covered date is assumed only next to an unrecorded one.
        // FR: Selon toute partie, une date présumée ne répète jamais un lieu
        //     enregistré, et une date couverte n'est présumée qu'à côté d'une
        //     date non couverte.
        for (var i = 0; i < any.days.length; i++) {
          final day = any.days[i];
          final assumed = day.assumed;
          if (assumed == null) continue;
          expect(
            day.places.any((p) => p.contains(assumed) || assumed.contains(p)),
            isFalse,
          );
          if (day.coveredByStay && i > 0 && i < any.days.length - 1) {
            expect(
              !any.days[i - 1].coveredByStay || !any.days[i + 1].coveredByStay,
              isTrue,
              reason: '${day.date} in history $n',
            );
          }
        }
      }
    });

    test('splitting a stay into regions never changes its country (STY-9)', () {
      final r = Random(3);
      for (var n = 0; n < 200; n++) {
        final stays =
            history(r).where((t) => t.status == TripStatus.actual).toList();
        final i = r.nextInt(stays.length);
        final target = stays[i];
        final end = target.departureDate ?? _today;
        final days = end.difference(target.arrivalDate).inDays;
        final cut = DateTime(
          target.arrivalDate.year,
          target.arrivalDate.month,
          target.arrivalDate.day + (days == 0 ? 0 : r.nextInt(days + 1)),
        );
        final regions = PlaceCatalog.regions[target.place.country] ??
            [target.place.country];
        final split = [
          ...stays.take(i),
          target.copyWith(
            departureDate: cut,
            place: regions[r.nextInt(regions.length)],
          ),
          _stay(
            regions[r.nextInt(regions.length)],
            cut,
            target.departureDate,
          ),
          ...stays.skip(i + 1),
        ];
        for (final convention in CountingConvention.values) {
          final before = _ledger(
            stays,
            from: DateTime(2023),
            convention: convention,
          );
          final after = _ledger(
            split,
            from: DateTime(2023),
            convention: convention,
          );
          for (final country in countries) {
            expect(
              after.daysIn(country),
              before.daysIn(country),
              reason: '${country.code}, $convention, history $n',
            );
          }
        }
      }
    });

    test('10,000 stays build a three-year ledger quickly', () {
      final stays = <Trip>[];
      var day = DateTime(1999);
      for (var i = 0; i < 10000; i++) {
        final end = DateTime(day.year, day.month, day.day + 2);
        stays.add(_stay(leaves[i % leaves.length], day, end));
        day = end;
      }
      final watch = Stopwatch()..start();
      final l =
          _ledger(stays, from: DateTime(2024), to: DateTime(2026, 12, 31));
      for (final place in leaves) {
        l.daysIn(place);
      }
      watch.stop();
      expect(l.daysIn(Place.canada), greaterThan(0));
      // EN: Generous on a desktop; the real check is an old phone (FEA-6).
      // FR: Large sur un ordinateur ; la vraie vérification est un vieux
      //     téléphone (FEA-6).
      expect(watch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
