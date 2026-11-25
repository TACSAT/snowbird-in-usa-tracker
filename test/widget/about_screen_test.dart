// EN: The About screen names the maker and opens the right page for each button, only
//     when tapped and in the app's language.
// FR: L'écran À propos nomme l'auteur et ouvre la bonne page pour chaque bouton,
//     seulement au toucher et dans la langue de l'appli.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:snowbird_in_usa_tracker/config/app_links.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/screens/about_screen.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final opened = <String>[];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    expect(options.mode, PreferredLaunchMode.externalApplication);
    opened.add(url);
    return true;
  }
}

void main() {
  for (final locale in ['en', 'fr']) {
    testWidgets('buttons open their pages: $locale', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final launcher = _FakeLauncher();
      UrlLauncherPlatform.instance = launcher;
      PackageInfo.setMockInitialValues(
        appName: 'x',
        packageName: 'x',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AboutScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('SENALOVIRA'), findsWidgets);
      expect(find.textContaining('teagarden.net'), findsWidgets);
      expect(find.textContaining('SnowBird'), findsNothing);
      expect(launcher.opened, isEmpty);

      final s = lookupAppLocalizations(Locale(locale));
      for (final (label, page) in [
        (s.aboutReport, AppPage.report),
        (s.aboutRequest, AppPage.request),
        (s.aboutStatus, AppPage.status),
        (s.aboutRoadmap, AppPage.roadmap),
        (s.aboutContribute, AppPage.contribute),
        (s.aboutPrivacyPolicy, AppPage.privacy),
      ]) {
        launcher.opened.clear();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(launcher.opened, [AppLinks.page(page, locale).toString()]);
      }
      launcher.opened.clear();
      await tester.tap(find.text(s.aboutSourceButton));
      await tester.pumpAndSettle();
      expect(launcher.opened, [AppLinks.sourceUrl]);
      expect(find.text(s.aboutContributeNote('teagarden.net')), findsOneWidget);
    });
  }
}
