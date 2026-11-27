// EN: Render smoke tests for the screens added this cycle (Settings, Reference,
//     About, and the FR-10 alert-editor changes). analyze proves they type-check
//     and the release build proves they compile; these prove they actually build a
//     widget tree at runtime without throwing or overflowing — the layer a physical
//     device would exercise first. The most load-bearing check is the alert editor:
//     switching to the since-last-visit kind must HIDE the rolling-window field.
//
// FR: Tests de fumée de rendu pour les écrans ajoutés ce cycle (Réglages,
//     Référence, À propos et les changements de l'éditeur d'alertes FR-10). analyze
//     prouve qu'ils compilent au type près et la build de release qu'ils compilent ;
//     ceux-ci prouvent qu'ils construisent réellement un arbre de widgets à
//     l'exécution sans lever d'exception ni déborder — la couche qu'un appareil
//     physique exercerait en premier. La vérification la plus porteuse est l'éditeur
//     d'alertes : passer au type « depuis le dernier séjour » doit MASQUER le champ
//     de fenêtre glissante.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/screens/about_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';

Widget _host({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings renders and the Dark option updates the controller',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final settings = SettingsController(storage);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: settings,
        child: _host(home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    expect(settings.themeMode, ThemeMode.system);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(settings.themeMode, ThemeMode.dark);

    await tester.scrollUntilVisible(find.text('Text size in this app'), 200);
    expect(find.text('Text size in this app'), findsOneWidget);
  });

  testWidgets('Reference page renders its intro and items', (tester) async {
    await tester.pumpWidget(_host(home: const ReferenceScreen()));
    await tester.pumpAndSettle();
    expect(find.text('US Substantial Presence Test'), findsOneWidget);
    expect(find.textContaining('not advice'), findsWidgets);
  });

  testWidgets('About renders version and the external-link buttons',
      (tester) async {
    // EN: Mock the platform package-info channel so the version line resolves.
    // FR: Simuler le canal de plateforme package-info pour résoudre la ligne de version.
    PackageInfo.setMockInitialValues(
      appName: 'SnowBird',
      packageName: 'ca.veidimadur.snowbird_in_usa_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await tester.pumpWidget(_host(home: const AboutScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.textContaining('Version 1.0.0'), findsOneWidget);
  });

  testWidgets(
      'Alert editor hides the window field for the since-last-visit kind',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: TripRepository(storage)),
          ChangeNotifierProvider.value(value: PresenceSettings(storage)),
        ],
        child: _host(home: const AlertEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // EN: Day-count is the default: the rolling-window field is present.
    // FR: Compte de jours par défaut : le champ de fenêtre glissante est présent.
    expect(find.text('Counted within the last (days)'), findsOneWidget);

    // EN: Switch to the since-last-visit kind.
    // FR: Passer au type « depuis le dernier séjour ».
    await tester.tap(find.text('Time since last visit'));
    await tester.pumpAndSettle();

    // EN: The window field is gone; the threshold label becomes the elapsed one.
    // FR: Le champ de fenêtre a disparu ; l'étiquette du seuil devient celle des
    //     jours écoulés.
    expect(find.text('Counted within the last (days)'), findsNothing);
    expect(
      find.text('Notify me after this many days since my last visit'),
      findsOneWidget,
    );
  });
}
