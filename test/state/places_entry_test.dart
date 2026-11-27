// EN: Tests for the Step 2 repository operations (REQUIREMENTS-places.md
//     section 5): moving on (STY-3), splitting a stay (STY-9), day visits
//     (WRK-5), recent places (PLC-9), and that visits count in every figure.
// FR: Tests des opérations du dépôt de l'étape 2 (REQUIREMENTS-places.md,
//     section 5) : changer de lieu (STY-3), diviser un séjour (STY-9), visites
//     d'un jour (WRK-5), lieux récents (PLC-9), et le fait que les visites
//     comptent dans chaque chiffre.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

final _today = DateTime(2026, 11, 26);
final _on = Place.parse('CA-ON');
final _yt = Place.parse('CA-YT');
final _ny = Place.parse('US-NY');

Future<(TripRepository, SharedPreferences, _Storage)> _repo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = _Storage(prefs);
  return (TripRepository(storage, now: () => _today), prefs, storage);
}

// EN: Storage whose writes can be made to fail, as a full disk would.
// FR: Stockage dont les écritures peuvent échouer, comme avec un disque plein.
class _Storage extends StorageService {
  _Storage(super.prefs);
  bool fail = false;

  @override
  Future<void> saveTrips(List<Trip> trips) async {
    if (fail) throw const StorageWriteException();
    return super.saveTrips(trips);
  }

  @override
  Future<void> saveVisits(List<DayVisit> visits) async {
    if (fail) throw const StorageWriteException();
    return super.saveVisits(visits);
  }
}

Trip _open(Place place, DateTime arrival) => Trip.create(
      arrivalDate: arrival,
      departureDate: null,
      status: TripStatus.actual,
      place: place,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('moving on (STY-3)', () {
    test('closes the ongoing stay and opens the next on the same date',
        () async {
      final (repo, _, _) = await _repo();
      final current = _open(_on, DateTime(2026, 11, 1));
      await repo.addTrip(current);
      final next = await repo.moveOn(current, DateTime(2026, 11, 20), _ny);

      expect(repo.tripCount, 2);
      final closed = repo.trips.firstWhere((t) => t.id == current.id);
      expect(closed.departureDate, DateTime(2026, 11, 20));
      expect(next.arrivalDate, DateTime(2026, 11, 20));
      expect(next.departureDate, isNull);
      expect(next.place, _ny);

      // EN: The crossing day counts in both places, by any part of the day.
      // FR: Le jour du passage compte dans les deux lieux, selon toute partie.
      final ledger = PresenceLedger.build(
        stays: repo.trips,
        from: DateTime(2026, 11),
        to: _today,
        today: _today,
      );
      expect(ledger.daysIn(_on), 20);
      expect(ledger.daysIn(_ny), 7);
      expect(ledger.crossingDays(), 1);
    });

    test('refuses a move before the stay began, or in the future', () async {
      final (repo, _, _) = await _repo();
      final current = _open(_on, DateTime(2026, 11, 10));
      await repo.addTrip(current);
      await expectLater(
        repo.moveOn(current, DateTime(2026, 11, 9), _ny),
        throwsA(
          isA<TripValidationException>().having(
            (e) => e.problem,
            'problem',
            TripProblem.moveBeforeArrival,
          ),
        ),
      );
      await expectLater(
        repo.moveOn(current, DateTime(2026, 11, 27), _ny),
        throwsA(
          isA<TripValidationException>().having(
            (e) => e.problem,
            'problem',
            TripProblem.futureArrival,
          ),
        ),
      );
      expect(repo.tripCount, 1);
      expect(repo.trips.single.departureDate, isNull);
    });

    test('only an ongoing actual stay can move on', () async {
      final (repo, _, _) = await _repo();
      final closed = Trip.create(
        arrivalDate: DateTime(2026, 1, 1),
        departureDate: DateTime(2026, 1, 5),
        status: TripStatus.actual,
      );
      await repo.addTrip(closed);
      await expectLater(
        repo.moveOn(closed, DateTime(2026, 1, 5), _ny),
        throwsArgumentError,
      );
    });

    test('a failed save changes neither stay', () async {
      final (repo, _, storage) = await _repo();
      final current = _open(_on, DateTime(2026, 11, 1));
      await repo.addTrip(current);
      storage.fail = true;
      await expectLater(
        repo.moveOn(current, DateTime(2026, 11, 20), _ny),
        throwsA(isA<StorageWriteException>()),
      );
      expect(repo.tripCount, 1);
      expect(repo.trips.single.departureDate, isNull);
    });
  });

  group('splitting a stay (STY-9)', () {
    test('two regions, same country, same total; exit details move on',
        () async {
      final (repo, _, _) = await _repo();
      final stay = Trip.create(
        arrivalDate: DateTime(2026, 6, 1),
        departureDate: DateTime(2026, 9, 30),
        status: TripStatus.actual,
        place: Place.canada,
        name: 'Summer',
        departureInfo: CrossingInfo.fromInput(location: 'Beaver Creek'),
      );
      await repo.addTrip(stay);
      final before = DayCounter.countDaysInCalendarYear(
        trips: repo.trips,
        year: 2026,
        asOf: _today,
        place: Place.canada,
      );
      await repo.splitStay(
        stay,
        DateTime(2026, 7, 12),
        before: Place.parse('CA-BC'),
        after: _yt,
      );
      final parts = repo.trips;
      expect(parts, hasLength(2));
      final first = parts.firstWhere((t) => t.id == stay.id);
      final second = parts.firstWhere((t) => t.id != stay.id);
      expect(first.place, Place.parse('CA-BC'));
      expect(first.departureDate, DateTime(2026, 7, 12));
      expect(first.departureInfo, isNull);
      expect(second.place, _yt);
      expect(second.arrivalDate, DateTime(2026, 7, 12));
      expect(second.departureDate, DateTime(2026, 9, 30));
      expect(second.departureInfo?.location, 'Beaver Creek');
      expect(second.name, 'Summer');
      expect(
        DayCounter.countDaysInCalendarYear(
          trips: parts,
          year: 2026,
          asOf: _today,
          place: Place.canada,
        ),
        before,
      );
    });

    test('an ongoing stay splits into a closed part and an ongoing part',
        () async {
      final (repo, _, _) = await _repo();
      final stay = _open(Place.canada, DateTime(2026, 11, 1));
      await repo.addTrip(stay);
      await repo.splitStay(stay, _today, before: _on, after: _yt);
      expect(repo.trips.where((t) => t.departureDate == null), hasLength(1));
      expect(
        repo.trips.firstWhere((t) => t.departureDate == null).place,
        _yt,
      );
    });

    test('refuses another country, or a date outside the stay', () async {
      final (repo, _, _) = await _repo();
      final stay = Trip.create(
        arrivalDate: DateTime(2026, 6, 1),
        departureDate: DateTime(2026, 6, 30),
        status: TripStatus.actual,
        place: Place.canada,
      );
      await repo.addTrip(stay);
      expect(
        () => repo.splitStay(
          stay,
          DateTime(2026, 6, 10),
          before: Place.canada,
          after: _ny,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repo.splitStay(
          stay,
          DateTime(2026, 7, 1),
          before: Place.canada,
          after: _yt,
        ),
        throwsA(
          isA<TripValidationException>().having(
            (e) => e.problem,
            'problem',
            TripProblem.splitDate,
          ),
        ),
      );
      expect(repo.tripCount, 1);
    });
  });

  group('day visits (WRK-5)', () {
    test('are saved under their own key and survive a restart', () async {
      final (repo, prefs, _) = await _repo();
      await repo.addVisit(
        DayVisit.create(date: DateTime(2026, 11, 3), place: _ny),
      );
      final stored = jsonDecode(prefs.getString('snowbird.visits.v1')!) as Map;
      expect(stored['schemaVersion'], StorageService.schemaVersion);
      expect((stored['visits'] as List).single['place'], 'US-NY');
      expect(prefs.getString('snowbird.trips.v1'), isNull);
      final again = TripRepository(StorageService(prefs), now: () => _today);
      expect(again.visits.single.place, _ny);
      await again.deleteVisit(again.visits.single.id);
      expect(TripRepository(StorageService(prefs)).visits, isEmpty);
    });

    test('an actual visit cannot be in the future; a planned one can',
        () async {
      final (repo, _, _) = await _repo();
      await expectLater(
        repo.addVisit(DayVisit.create(date: DateTime(2026, 12, 1), place: _ny)),
        throwsA(isA<TripValidationException>()),
      );
      await repo.addVisit(
        DayVisit.create(
          date: DateTime(2026, 12, 1),
          place: _ny,
          status: TripStatus.planned,
        ),
      );
      expect(repo.visits, hasLength(1));
    });

    test('count in US figures like a same-day trip, never as a stay', () async {
      final (repo, _, _) = await _repo();
      await repo.addTrip(_open(_on, DateTime(2026, 1, 1)));
      await repo.addVisit(
        DayVisit.create(date: DateTime(2026, 3, 14), place: Place.unitedStates),
      );
      await repo.addVisit(
        DayVisit.create(date: DateTime(2026, 3, 14), place: _ny),
      );
      expect(repo.tripCount, 1);
      expect(
        DayCounter.countDaysInCalendarYear(
          trips: repo.countedStays,
          year: 2026,
          asOf: _today,
        ),
        1,
        reason: 'two visits on one date are one US day',
      );
      expect(
        DayCounter.substantialPresence(trips: repo.countedStays, asOf: _today)
            .currentYearDays,
        1,
      );
    });
  });

  test('recent places: most recent first, each once', () async {
    final (repo, _, _) = await _repo();
    await repo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2026, 1, 1),
        departureDate: DateTime(2026, 1, 10),
        status: TripStatus.actual,
        place: _on,
      ),
    );
    await repo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2026, 2, 1),
        departureDate: DateTime(2026, 2, 10),
        status: TripStatus.actual,
        place: _ny,
      ),
    );
    await repo.addTrip(
      Trip.create(
        arrivalDate: DateTime(2026, 3, 1),
        departureDate: DateTime(2026, 3, 10),
        status: TripStatus.actual,
        place: _on,
      ),
    );
    await repo
        .addVisit(DayVisit.create(date: DateTime(2026, 4, 1), place: _yt));
    expect(repo.recentPlaces(), [_yt, _on, _ny]);
    expect(repo.recentPlaces(limit: 1), [_yt]);
  });
}
