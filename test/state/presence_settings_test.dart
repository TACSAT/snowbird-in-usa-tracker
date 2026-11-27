// EN: Tests for the table and home base preferences: they persist, damaged
//     values fall back to the defaults, and the home base cannot be on without
//     a place.
// FR: Tests des préférences du tableau et du lieu de résidence : elles
//     persistent, les valeurs abîmées reviennent aux valeurs par défaut, et le
//     lieu de résidence ne peut pas être activé sans lieu.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';

Future<(PresenceSettings, SharedPreferences)> _settings([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return (PresenceSettings(StorageService(prefs)), prefs);
}

PresenceSettings _reload(SharedPreferences prefs) =>
    PresenceSettings(StorageService(prefs));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final on = Place.parse('CA-ON');

  test('defaults: automatic table, home off, nothing expanded', () async {
    final (s, _) = await _settings();
    expect(s.tracked, isNull);
    expect(s.homeEnabled, isFalse);
    expect(s.home.isOff, isTrue);
    expect(s.isExpanded(Place.canada), isFalse);
  });

  test('a chosen list keeps order, convention and pin across restarts',
      () async {
    final (s, prefs) = await _settings();
    await s.setAutomatic(false, initial: [Place.canada, Place.unitedStates]);
    await s.addTracked(on);
    await s.addTracked(on);
    await s.moveTracked(on, -1);
    await s.updateTracked(
      s.tracked!.first.copyWith(
        convention: CountingConvention.endOfDay,
        pinned: true,
      ),
    );
    final again = _reload(prefs);
    expect(
      again.tracked!.map((t) => t.place),
      [Place.canada, on, Place.unitedStates],
    );
    expect(again.tracked!.first.convention, CountingConvention.endOfDay);
    expect(again.tracked!.first.pinned, isTrue);
    await again.moveTracked(Place.canada, -1);
    expect(again.tracked!.first.place, Place.canada, reason: 'already first');
    await again.removeTracked(on);
    await again.setAutomatic(true);
    expect(_reload(prefs).tracked, isNull);
  });

  test('expanded countries are remembered', () async {
    final (s, prefs) = await _settings();
    await s.setExpanded(Place.canada, true);
    expect(_reload(prefs).isExpanded(Place.canada), isTrue);
    await s.setExpanded(Place.canada, false);
    expect(_reload(prefs).isExpanded(Place.canada), isFalse);
  });

  test('home base: needs a place; first period turns it on; off keeps it',
      () async {
    final (s, prefs) = await _settings();
    await s.setHomeEnabled(true);
    expect(s.homeEnabled, isFalse);
    await s.addHomePeriod(HomePeriod(place: on, from: DateTime(2020)));
    expect(s.homeEnabled, isTrue);
    await s.addHomePeriod(
      HomePeriod(place: Place.parse('CA-QC'), from: DateTime(2024, 7)),
    );
    await s.setHomeEnabled(false);
    expect(s.home.isOff, isTrue);
    final again = _reload(prefs);
    expect(again.homeEnabled, isFalse);
    expect(again.homePeriods, hasLength(2));
    await again.setHomeEnabled(true);
    expect(again.home.placeOn(DateTime(2025)), Place.parse('CA-QC'));
    await again.removeHomePeriod(again.homePeriods.first);
    await again.removeHomePeriod(again.homePeriods.first);
    expect(again.homeEnabled, isFalse, reason: 'nothing left to assume');
  });

  test('damaged preferences fall back to the defaults', () async {
    final (s, _) = await _settings({
      'snowbird.places.tracked.v1': '[{"place":"Ontario"}]',
      'snowbird.home.v1': '{"enabled":true,"periods":[{"place":"CA"}]}',
    });
    expect(s.tracked, isNull);
    expect(s.homeEnabled, isFalse);
  });
}
