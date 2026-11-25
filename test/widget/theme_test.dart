// EN: Brightness choice (FR-20): follows the phone by default and live, can be forced to
//     light or dark, and survives a restart. Checked on the rendered theme rather than
//     on the stored setting alone.
// FR: Choix de luminosité (FR-20) : suit le téléphone par défaut et en direct, peut être
//     forcé clair ou sombre, et survit à un redémarrage. Vérifié sur le thème affiché
//     plutôt que sur le seul réglage enregistré.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/app.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

void main() {
  const light = Brightness.light;
  const dark = Brightness.dark;

  late StorageService storage;

  // EN: Rebuilding everything from storage is what a relaunch does.
  // FR: Tout reconstruire depuis le stockage, comme le fait un relancement.
  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider.value(value: SettingsController(storage)),
          ChangeNotifierProvider.value(value: TripRepository(storage)),
        ],
        child: const SnowBirdApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Brightness> shown(WidgetTester tester, Brightness phone) async {
    tester.platformDispatcher.platformBrightnessTestValue = phone;
    await tester.pumpAndSettle();
    final screen = find.byType(TripListScreen, skipOffstage: false);
    return Theme.of(tester.element(screen)).brightness;
  }

  Future<void> expectShown(
    WidgetTester tester, {
    required Brightness phoneLight,
    required Brightness phoneDark,
  }) async {
    expect(await shown(tester, light), phoneLight);
    expect(await shown(tester, dark), phoneDark);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'snowbird.flags.disclaimerAck.v1': true,
      'snowbird.flags.backupReminderShown.v1': true,
      'snowbird.settings.locale.v1': 'en',
    });
    storage = StorageService(await SharedPreferences.getInstance());
  });

  testWidgets('follows the phone by default', (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await launch(tester);
    await expectShown(tester, phoneLight: light, phoneDark: dark);
  });

  testWidgets('each choice applies at once and survives a restart',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await launch(tester);
    for (final (label, phoneLight, phoneDark) in [
      ('Dark', dark, dark),
      ('Light', light, light),
      ('Follow phone', light, dark),
    ]) {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()))
          .ignore();
      await tester.pumpAndSettle();
      // EN: "Follow phone" also appears under Language, above; take the last one.
      // FR: « Follow phone » figure aussi sous Langue, plus haut ; prendre le dernier.
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await expectShown(tester, phoneLight: phoneLight, phoneDark: phoneDark);
      await launch(tester);
      await expectShown(tester, phoneLight: phoneLight, phoneDark: phoneDark);
    }
  });
}
