// EN: Tests that user history survives bad storage and that the repository refuses
//     overlapping or future "actual" trips. These failures are unrecoverable for
//     the user (no cloud copy), so every path is pinned here.
// FR: Tests garantissant que l'historique survit à un stockage fautif et que le
//     dépôt refuse les séjours « réels » chevauchants ou futurs. Ces pannes sont
//     irrécupérables pour l'utilisateur (aucune copie infonuagique), donc chaque
//     chemin est verrouillé ici.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

const _key = 'snowbird.trips.v1';
const _quarantine = 'snowbird.trips.v1.quarantine';

Trip _trip(
  String arrival,
  String? departure, {
  TripStatus status = TripStatus.actual,
}) =>
    Trip.create(
      arrivalDate: DateTime.parse(arrival),
      departureDate: departure == null ? null : DateTime.parse(departure),
      status: status,
    );

Future<(StorageService, SharedPreferences)> _storage([Object? raw]) async {
  SharedPreferences.setMockInitialValues({if (raw != null) _key: raw});
  final prefs = await SharedPreferences.getInstance();
  return (StorageService(prefs), prefs);
}

// EN: Simulates a device that refuses the write (disk full, I/O error).
// FR: Simule un appareil qui refuse l'écriture (disque plein, erreur d'E/S).
class _FailingStorage extends StorageService {
  _FailingStorage(super.prefs);
  bool fail = false;
  @override
  Future<void> saveTrips(List<Trip> trips) async {
    if (fail) throw const StorageWriteException();
    return super.saveTrips(trips);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final good = _trip('2026-01-01', '2026-01-02');

  TripRepository repoOf(StorageService s) =>
      TripRepository(s, now: () => DateTime(2026, 11, 24, 15));

  group('storage', () {
    test('a legacy v1 bare list loads and is rewritten with its version',
        () async {
      final (s, prefs) = await _storage(jsonEncode([good.toJson()]));
      final repo = repoOf(s);
      expect(repo.tripCount, 1);
      expect(s.loadProblem, StorageLoadProblem.none);
      await repo.addTrip(_trip('2026-02-01', '2026-02-02'));
      final stored = jsonDecode(prefs.getString(_key)!) as Map;
      expect(stored['schemaVersion'], StorageService.schemaVersion);
      expect(repoOf(StorageService(prefs)).tripCount, 2);
      expect(prefs.getStringList(_quarantine), isNull);
    });

    test('unreadable data is copied aside before the first write', () async {
      const broken = '[{"id":';
      final (s, prefs) = await _storage(broken);
      final repo = repoOf(s);
      expect(s.loadProblem, StorageLoadProblem.unreadable);
      expect(prefs.getString(_key), broken);
      await repo.addTrip(good);
      expect(prefs.getStringList(_quarantine), [broken]);
      expect(repo.tripCount, 1);
    });

    test('a wrong-typed field skips one record, keeps the rest', () async {
      for (final field in ['notes', 'id', 'status', 'arrivalDate', 'name']) {
        final raw = jsonEncode([
          good.toJson(),
          {...good.toJson(), field: 5},
          'not an object',
          {
            ...good.toJson(),
            'arrivalInfo': {'location': 5},
          },
        ]);
        final (s, prefs) = await _storage(raw);
        final repo = repoOf(s);
        expect(repo.tripCount, 1, reason: field);
        expect(s.loadProblem, StorageLoadProblem.unreadable);
        await repo.deleteTrip(good.id);
        expect(prefs.getStringList(_quarantine), [raw]);
      }
    });

    test('a non-string stored value does not crash', () async {
      final (s, _) = await _storage(42);
      expect(repoOf(s).tripCount, 0);
      expect(s.loadProblem, StorageLoadProblem.unreadable);
    });

    test('data from a newer app version is never overwritten', () async {
      final raw = jsonEncode({'schemaVersion': 999, 'trips': <Object>[]});
      final (s, prefs) = await _storage(raw);
      final repo = repoOf(s);
      expect(s.loadProblem, StorageLoadProblem.newerVersion);
      await expectLater(
        repo.addTrip(good),
        throwsA(isA<StorageWriteException>()),
      );
      expect(prefs.getString(_key), raw);
      expect(repo.tripCount, 0);
    });

    test('the same rules protect alerts', () async {
      SharedPreferences.setMockInitialValues({
        'snowbird.alerts.v1': '[{"id":5}]',
      });
      final prefs = await SharedPreferences.getInstance();
      final s = StorageService(prefs);
      expect(s.loadAlerts(), isEmpty);
      await s.saveAlerts([]);
      expect(
        prefs.getStringList('snowbird.alerts.v1.quarantine'),
        ['[{"id":5}]'],
      );
    });

    test('a failed save leaves memory unchanged and later saves work',
        () async {
      SharedPreferences.setMockInitialValues({});
      final s = _FailingStorage(await SharedPreferences.getInstance());
      final repo = repoOf(s);
      s.fail = true;
      await expectLater(
        repo.addTrip(good),
        throwsA(isA<StorageWriteException>()),
      );
      expect(repo.tripCount, 0);
      s.fail = false;
      await repo.addTrip(good);
      expect(repo.tripCount, 1);
    });

    test('an open trip round-trips; a missing departure key is malformed',
        () async {
      final t = _trip('2026-11-01', null);
      expect(Trip.fromJson(t.toJson()).departureDate, isNull);
      final json = t.toJson()..remove('departureDate');
      expect(() => Trip.fromJson(json), throwsFormatException);
    });
  });

  group('model', () {
    test('a planned trip cannot be open', () {
      expect(
        () => _trip('2026-01-01', null, status: TripStatus.planned),
        throwsArgumentError,
      );
    });

    test('copyWith can close and reopen a trip', () {
      final t = _trip('2026-11-01', null);
      final closed = t.copyWith(departureDate: DateTime(2026, 11, 5));
      expect(closed.daysInUS, 5);
      expect(closed.copyWith(departureDate: null).departureDate, isNull);
      expect(closed.copyWith(name: 'x').departureDate, DateTime(2026, 11, 5));
    });

    test('daysPresent clips actual trips, not planned ones', () {
      final asOf = DateTime(2026, 11, 24, 23);
      expect(_trip('2026-11-01', null).daysPresent(asOf), 24);
      expect(_trip('2026-11-01', '2026-12-31').daysPresent(asOf), 24);
      expect(_trip('2026-12-01', '2026-12-31').daysPresent(asOf), 0);
      expect(
        _trip('2026-12-01', '2026-12-31', status: TripStatus.planned)
            .daysPresent(asOf),
        31,
      );
    });
  });

  group('validation', () {
    Future<TripRepository> repo() async => repoOf((await _storage()).$1);
    Matcher problem(TripProblem p) => throwsA(
          isA<TripValidationException>().having((e) => e.problem, 'problem', p),
        );

    test('overlap is blocked and nothing is stored', () async {
      final r = await repo();
      await r.addTrip(_trip('2026-01-01', '2026-01-10'));
      for (final (a, d) in [
        ('2026-01-09', '2026-01-20'),
        ('2026-01-01', '2026-01-10'),
        ('2026-01-05', '2026-01-05'),
        ('2025-12-01', '2026-02-01'),
      ]) {
        await expectLater(
          r.addTrip(_trip(a, d)),
          problem(TripProblem.overlap),
        );
      }
      expect(r.tripCount, 1);
    });

    test('a shared border day and same-day day-trips are allowed', () async {
      final r = await repo();
      await r.addTrip(_trip('2026-01-01', '2026-01-10'));
      await r.addTrip(_trip('2026-01-10', '2026-01-10'));
      await r.addTrip(_trip('2026-01-10', '2026-01-10'));
      await r.addTrip(_trip('2026-01-10', '2026-01-20'));
      expect(r.tripCount, 4);
    });

    test('an open trip blocks any later actual trip', () async {
      final r = await repo();
      await r.addTrip(_trip('2026-11-01', null));
      await expectLater(
        r.addTrip(_trip('2026-11-10', '2026-11-12')),
        problem(TripProblem.overlap),
      );
      await expectLater(
        r.addTrip(_trip('2026-11-01', null)),
        problem(TripProblem.overlap),
      );
      await r.addTrip(_trip('2026-10-01', '2026-11-01'));
    });

    test('planned alternatives may overlap anything', () async {
      final r = await repo();
      await r.addTrip(_trip('2026-11-01', null));
      for (var i = 0; i < 2; i++) {
        await r.addTrip(
          _trip('2026-12-01', '2026-12-20', status: TripStatus.planned),
        );
      }
      expect(r.tripCount, 3);
    });

    test('an actual arrival in the future is blocked; today is fine', () async {
      final r = await repo();
      await expectLater(
        r.addTrip(_trip('2026-11-25', '2026-11-26')),
        problem(TripProblem.futureArrival),
      );
      await r.addTrip(_trip('2026-11-24', '2026-12-20'));
    });

    test('update is validated but never against itself', () async {
      final r = await repo();
      final a = _trip('2026-01-01', '2026-01-10');
      await r.addTrip(a);
      await r.addTrip(_trip('2026-02-01', '2026-02-10'));
      await r.updateTrip(a.copyWith(departureDate: DateTime(2026, 1, 12)));
      await expectLater(
        r.updateTrip(a.copyWith(departureDate: DateTime(2026, 2, 5))),
        problem(TripProblem.overlap),
      );
      await r.updateTrip(a.copyWith(status: TripStatus.planned));
      await r.addTrip(_trip('2026-01-05', '2026-01-06'));
      await expectLater(
        r.updateTrip(a.copyWith(departureDate: DateTime(2026, 1, 12))),
        problem(TripProblem.overlap),
      );
    });

    test('notes on a legacy overlapping trip can still be edited', () async {
      final a = _trip('2026-01-01', '2026-01-10');
      final (s, _) = await _storage(
        jsonEncode([
          a.toJson(),
          _trip('2026-01-05', '2026-01-15').toJson(),
        ]),
      );
      final r = repoOf(s);
      await r.updateTrip(a.copyWith(notes: 'hello'));
      expect(r.trips.any((t) => t.notes == 'hello'), isTrue);
    });

    test('concurrent adds are serialised, so overlap cannot race in', () async {
      final r = await repo();
      final first = r.addTrip(_trip('2026-01-01', '2026-01-10'));
      final second = expectLater(
        r.addTrip(_trip('2026-01-05', '2026-01-15')),
        problem(TripProblem.overlap),
      );
      await first;
      await second;
      expect(r.tripCount, 1);
    });
  });
}
