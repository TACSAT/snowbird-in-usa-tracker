// EN: Tests that user preferences (FR-20) actually persist — the whole point of the
//     feature is that a choice survives an app restart. We prove it by writing
//     through one controller and reading back through a SECOND controller built from
//     the same storage (a fresh instance is what a relaunch produces). Also checks
//     the two guards: null locale clears the override, and an out-of-range text
//     scale is clamped.
//
// FR: Tests que les préférences (FR-20) persistent réellement — tout l'intérêt est
//     qu'un choix survive à un redémarrage. On le prouve en écrivant via un
//     contrôleur et en relisant via un SECOND contrôleur construit sur le même
//     stockage (une nouvelle instance est ce que produit un relancement). Vérifie
//     aussi les deux gardes : une locale null efface l'outrepassement, et une
//     échelle de texte hors plage est serrée.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';

Future<StorageService> freshStorage([
  Map<String, Object> seed = const {},
]) async {
  SharedPreferences.setMockInitialValues(seed);
  return StorageService(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults follow the phone / framework on a fresh install', () async {
    final c = SettingsController(await freshStorage());
    expect(c.locale, isNull);
    expect(c.themeMode, ThemeMode.system);
    expect(c.textScale, 1.0);
  });

  test('language, theme, and text size persist across a relaunch', () async {
    final storage = await freshStorage();
    final first = SettingsController(storage);
    await first.setLocale(const Locale('fr'));
    await first.setThemeMode(ThemeMode.dark);
    await first.setTextScale(1.4);

    // EN: A second controller from the same storage = what a relaunch loads.
    // FR: Un second contrôleur depuis le même stockage = ce qu'un relancement charge.
    final reloaded = SettingsController(storage);
    expect(reloaded.locale, const Locale('fr'));
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.textScale, 1.4);
  });

  test(
      'setting a null locale clears the override (back to following the phone)',
      () async {
    final storage = await freshStorage();
    final c = SettingsController(storage);
    await c.setLocale(const Locale('fr'));
    await c.setLocale(null);
    expect(SettingsController(storage).locale, isNull);
  });

  test('an out-of-range text scale is clamped to the allowed bounds', () async {
    final storage = await freshStorage();
    final c = SettingsController(storage);
    await c.setTextScale(9.0);
    expect(c.textScale, kMaxTextScale);
    await c.setTextScale(0.1);
    expect(c.textScale, kMinTextScale);
  });

  test('a stored scale beyond bounds is clamped on load', () async {
    final storage =
        await freshStorage({'snowbird.settings.textScale.v1': 42.0});
    expect(SettingsController(storage).textScale, kMaxTextScale);
  });
}
