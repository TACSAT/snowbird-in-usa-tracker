// EN: Migration to schema version 3 (REQUIREMENTS-places.md section 12). The
//     promise under test: every United States count and the Substantial Presence
//     figure are IDENTICAL before and after (MIG-1). "Before" is the frozen copy
//     of the old engine in test/support; "after" is today's code reading the same
//     stored text through StorageService. Hundreds of random histories are
//     compared, not a handful of hand-picked ones.
// FR: Migration vers la version 3 du schéma (REQUIREMENTS-places.md, section 12).
//     La promesse testée : chaque total des États-Unis et le chiffre de présence
//     substantielle sont IDENTIQUES avant et après (MIG-1). « Avant » est la copie
//     figée de l'ancien moteur dans test/support ; « après » est le code actuel
//     lisant le même texte enregistré par StorageService. Des centaines
//     d'historiques aléatoires sont comparés, pas quelques cas choisis à la main.

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/logic/day_counter.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';

import '../support/legacy_day_counter.dart';
import '../support/legacy_trip.dart';

const _key = 'snowbird.trips.v1';
const _premigration = 'snowbird.trips.v1.premigration';
final _today = DateTime(2026, 11, 26);

// EN: A random old-format history: actual trips in sequence (some sharing a
//     border day, perhaps one still open), planned trips anywhere, all US.
// FR: Un historique aléatoire à l'ancien format : séjours réels à la suite
//     (certains partageant un jour de frontière, peut-être un encore ouvert),
//     séjours planifiés n'importe où, tous aux États-Unis.
List<LegacyTrip> _legacyHistory(Random r) {
  final trips = <LegacyTrip>[];
  var day = DateTime(2022, 1, 1 + r.nextInt(500));
  final count = r.nextInt(30);
  for (var i = 0; i < count && day.isBefore(_today); i++) {
    var end = DateTime(day.year, day.month, day.day + r.nextInt(120));
    if (end.isAfter(_today)) end = _today;
    final open = i == count - 1 && r.nextBool();
    trips.add(
      LegacyTrip.create(
        arrivalDate: day,
        departureDate: open ? null : end,
        status: LegacyTripStatus.actual,
        name: r.nextBool() ? 'Trip $i' : null,
      ),
    );
    if (open) break;
    day = DateTime(end.year, end.month, end.day + r.nextInt(3) * r.nextInt(60));
  }
  for (var i = r.nextInt(4); i > 0; i--) {
    final start = DateTime(2025, 1, 1 + r.nextInt(900));
    trips.add(
      LegacyTrip.create(
        arrivalDate: start,
        departureDate:
            DateTime(start.year, start.month, start.day + r.nextInt(90)),
        status: LegacyTripStatus.planned,
      ),
    );
  }
  return trips..shuffle(r);
}

Future<(StorageService, SharedPreferences)> _load(String raw) async {
  SharedPreferences.setMockInitialValues({_key: raw});
  final prefs = await SharedPreferences.getInstance();
  return (StorageService(prefs), prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const actual = {LegacyTripStatus.actual};
  const both = {LegacyTripStatus.actual, LegacyTripStatus.planned};
  const newActual = {TripStatus.actual};
  const newBoth = {TripStatus.actual, TripStatus.planned};

  test('every US count and the SPT are identical after migration (MIG-1)',
      () async {
    final r = Random(2026);
    for (var n = 0; n < 300; n++) {
      final old = _legacyHistory(r);
      final raw = n.isEven
          ? jsonEncode({
              'schemaVersion': 2,
              'trips': [for (final t in old) t.toJson()],
            })
          // EN: Version 1 was a bare list; it must migrate too.
          // FR: La version 1 était une simple liste ; elle doit migrer aussi.
          : jsonEncode([for (final t in old) t.toJson()]);
      final (storage, _) = await _load(raw);
      final migrated = storage.loadTrips();
      expect(storage.loadProblem, StorageLoadProblem.none);
      expect(migrated, hasLength(old.length));
      expect(migrated.every((t) => t.place == Place.unitedStates), isTrue);

      for (var year = 2022; year <= 2028; year++) {
        for (final (o, s) in [(actual, newActual), (both, newBoth)]) {
          expect(
            DayCounter.countDaysInCalendarYear(
              trips: migrated,
              year: year,
              asOf: _today,
              includeStatuses: s,
            ),
            LegacyDayCounter.countDaysInCalendarYear(
              trips: old,
              year: year,
              asOf: _today,
              includeStatuses: o,
            ),
            reason: 'year $year, history $n',
          );
        }
      }
      for (final window in [1, 30, 180, 365, 1095]) {
        expect(
          DayCounter.countDaysInLastDays(
            trips: migrated,
            days: window,
            today: _today,
          ),
          LegacyDayCounter.countDaysInLastDays(
            trips: old,
            days: window,
            today: _today,
          ),
        );
      }
      final sptNew =
          DayCounter.substantialPresence(trips: migrated, asOf: _today);
      final sptOld =
          LegacyDayCounter.substantialPresence(trips: old, asOf: _today);
      expect(sptNew.totalSixths, sptOld.totalSixths, reason: 'history $n');
      expect(sptNew.formatted, sptOld.formatted);
      expect(
        DayCounter.firstDateReachingThreshold(
          trips: migrated,
          thresholdDays: 120,
          windowDays: 365,
          from: DateTime(2023),
        ),
        LegacyDayCounter.firstDateReachingThreshold(
          trips: old,
          thresholdDays: 120,
          windowDays: 365,
          from: DateTime(2023),
        ),
      );
      expect(
        DayCounter.lastDeparture(trips: migrated),
        LegacyDayCounter.lastDeparture(trips: old),
      );

      // EN: And the new engine, by its default convention, agrees as well.
      // FR: Et le nouveau moteur, selon sa convention par défaut, concorde aussi.
      final ledger = PresenceLedger.build(
        stays: migrated,
        from: DateTime(2022),
        to: DateTime(2026, 12, 31),
        today: _today,
      );
      expect(
        ledger.daysIn(Place.unitedStates, start: DateTime(2026)),
        LegacyDayCounter.countDaysInCalendarYear(
          trips: old,
          year: 2026,
          asOf: _today,
        ),
      );
      expect(
        ledger.regionNotRecorded(Place.unitedStates),
        ledger.daysIn(Place.unitedStates),
      );
    }
  });

  group('storage', () {
    final oldTrip = LegacyTrip.create(
      arrivalDate: DateTime(2026, 1, 1),
      departureDate: DateTime(2026, 1, 10),
      status: LegacyTripStatus.actual,
    );
    final v2 = jsonEncode({
      'schemaVersion': 2,
      'trips': [oldTrip.toJson()],
    });

    test('version 2 data loads, and nothing is written just by reading',
        () async {
      final (storage, prefs) = await _load(v2);
      expect(storage.loadTrips().single.place, Place.unitedStates);
      expect(prefs.getString(_key), v2);
      expect(prefs.getString(_premigration), isNull);
    });

    test('the first save writes version 3 with places, then tidies up',
        () async {
      final (storage, prefs) = await _load(v2);
      await storage.saveTrips(storage.loadTrips());
      final stored = jsonDecode(prefs.getString(_key)!) as Map;
      expect(stored['schemaVersion'], 3);
      expect((stored['trips'] as List).single['place'], 'US');
      expect(prefs.getString(_premigration), isNull);
      final reread = StorageService(prefs).loadTrips().single;
      expect(reread.arrivalDate, DateTime(2026, 1, 1));
      expect(reread.departureDate, DateTime(2026, 1, 10));
    });

    test('a failed first save keeps the original aside (MIG-3)', () async {
      final (_, prefs) = await _load(v2);
      final storage = _FailOnMainWrite(prefs);
      final trips = storage.loadTrips();
      await expectLater(
        storage.saveTrips(trips),
        throwsA(isA<StorageWriteException>()),
      );
      expect(prefs.getString(_premigration), v2);
      expect(prefs.getString(_key), v2);
    });

    test('version 3 data needs no copy kept aside', () async {
      final (storage, prefs) = await _load(
        jsonEncode({
          'schemaVersion': 3,
          'trips': [
            {...oldTrip.toJson(), 'place': 'CA-ON'},
          ],
        }),
      );
      final trips = storage.loadTrips();
      expect(trips.single.place, Place.parse('CA-ON'));
      await storage.saveTrips(trips);
      expect(prefs.getString(_premigration), isNull);
    });

    test('data from a newer version is still refused, not overwritten',
        () async {
      final raw = jsonEncode({'schemaVersion': 4, 'trips': <Object>[]});
      final (storage, prefs) = await _load(raw);
      expect(storage.loadTrips(), isEmpty);
      expect(storage.loadProblem, StorageLoadProblem.newerVersion);
      await expectLater(
        storage.saveTrips(const []),
        throwsA(isA<StorageWriteException>()),
      );
      expect(prefs.getString(_key), raw);
    });
  });
}

// EN: SharedPreferences whose write of the main trips key fails, as a full
//     disk would; every other write succeeds. Proves the order of MIG-3: the
//     copy is put aside first, and survives a failed main write.
// FR: SharedPreferences dont l'écriture de la clé principale des séjours
//     échoue, comme avec un disque plein ; toute autre écriture réussit. Prouve
//     l'ordre de MIG-3 : la copie est mise de côté d'abord, et survit à
//     l'échec de l'écriture principale.
class _FailOnMainWrite extends StorageService {
  _FailOnMainWrite(SharedPreferences prefs) : super(_Prefs(prefs));
}

class _Prefs implements SharedPreferences {
  final SharedPreferences inner;
  _Prefs(this.inner);

  @override
  Object? get(String key) => inner.get(key);

  @override
  String? getString(String key) => inner.getString(key);

  @override
  List<String>? getStringList(String key) => inner.getStringList(key);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      inner.setStringList(key, value);

  @override
  Future<bool> remove(String key) => inner.remove(key);

  @override
  Future<bool> setString(String key, String value) async =>
      key == _key ? false : inner.setString(key, value);

  // EN: Anything else is not used by StorageService's trip path; fail loudly.
  // FR: Le reste n'est pas utilisé par le chemin des séjours de StorageService ;
  //     échouer bruyamment.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
