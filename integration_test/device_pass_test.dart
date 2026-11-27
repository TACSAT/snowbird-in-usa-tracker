// EN: The Step 7 device pass, on a simulator, emulator or phone
//     (REQUIREMENTS-places.md section 16). Unlike the widget tests, this runs
//     on the real platform: real fonts, real SharedPreferences storage, real
//     PDF layout and rasterising. It:
//     1. writes trips in the OLD (schema 2) format to real storage and checks
//        the new build reads them as United States stays, and shows the
//        one-time note (checklist item 7, MIG-1, MIG-4);
//     2. adds stays in several places, a day visit, a home base and days
//        worked, then captures every screen in English and French, and again
//        at the largest app text with dark mode and high contrast;
//     3. builds the PDF, its first page as an image, the text, CSV and the
//        day-by-day ledger exactly as the export screen would, and hands them
//        to the host for a person to open (checklist item 4);
//     4. captures the lock screen.
//     Run it with tools/device_pass.sh; files land in build/device_pass/.
// FR: La vérification sur appareil de l'étape 7, sur simulateur, émulateur ou
//     téléphone (REQUIREMENTS-places.md, section 16). Contrairement aux tests
//     d'interface, elle s'exécute sur la vraie plateforme : vraies polices,
//     vrai stockage SharedPreferences, vraie mise en page et vrai rendu PDF.
//     Elle :
//     1. écrit des séjours à l'ANCIEN format (schéma 2) dans le vrai stockage
//        et vérifie que la nouvelle version les lit comme des séjours aux
//        États-Unis, et montre la note unique (point 7 de la liste, MIG-1,
//        MIG-4) ;
//     2. ajoute des séjours dans plusieurs lieux, une visite d'un jour, un
//        domicile et des jours travaillés, puis capture chaque écran en anglais
//        et en français, puis au plus grand texte de l'appli en mode sombre et
//        contraste élevé ;
//     3. construit le PDF, sa première page en image, le texte, le CSV et le
//        registre jour par jour exactement comme l'écran d'export, et les
//        remet à l'hôte pour qu'une personne les ouvre (point 4 de la liste) ;
//     4. capture l'écran de verrouillage.
//     À lancer avec tools/device_pass.sh ; les fichiers arrivent dans
//     build/device_pass/.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/app.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/explore_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/export_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/places_settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/split_stay_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/visits_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/work_calendar_screen.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/device_auth.dart';
import 'package:snowbird_in_usa_tracker/services/record_exporter.dart';
import 'package:snowbird_in_usa_tracker/services/record_text.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

// EN: No notifications on a simulator pass: scheduling is checked by unit
//     tests and on a real phone (checklist items 1 to 3).
// FR: Aucune notification pendant la vérification sur simulateur : la
//     planification est vérifiée par les tests unitaires et sur un vrai
//     téléphone (points 1 à 3 de la liste).
class _NoScheduler implements AlertScheduler {
  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Future<void> reschedule(List<ScheduledAlert> schedule) async {}
}

class _Auth extends DeviceAuth {
  final bool pass;
  const _Auth(this.pass);

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> check(String reason) async => pass;
}

DateTime _ago(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - n);
}

String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final os = Platform.isIOS ? 'ios' : 'android';
  final files = <String, String>{};
  var converted = false;

  Future<void> shot(WidgetTester tester, String name) async {
    if (Platform.isAndroid && !converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
    }
    await tester.pumpAndSettle();
    await binding.takeScreenshot('${os}_$name');
  }

  testWidgets('device pass', (tester) async {
    // EN: 1. Old-format data in REAL storage, as an earlier build left it.
    // FR: 1. Des données à l'ancien format dans le VRAI stockage, comme une
    //     version précédente les a laissées.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('snowbird.flags.disclaimerAck.v1', true);
    await prefs.setBool('snowbird.flags.backupReminderShown.v1', true);
    await prefs.setString(
      'snowbird.trips.v1',
      jsonEncode({
        'schemaVersion': 2,
        'trips': [
          {
            'id': 'old-1',
            'arrivalDate': _iso(_ago(330)),
            'departureDate': _iso(_ago(240)),
            'status': 'actual',
            'name': 'Winter in Florida',
          },
          {
            'id': 'old-2',
            'arrivalDate': _iso(_ago(200)),
            'departureDate': _iso(_ago(190)),
            'status': 'actual',
          },
        ],
      }),
    );
    final storage = StorageService(prefs);
    final trips = TripRepository(storage);
    expect(trips.tripCount, 2);
    expect(trips.trips.every((t) => t.place == Place.unitedStates), isTrue);
    expect(storage.loadedOlderTrips, isTrue);

    final settings = SettingsController(storage);
    final places = PresenceSettings(storage);
    final alerts = AlertRepository(storage, trips, scheduler: _NoScheduler());
    Widget app({DeviceAuth auth = const _Auth(true)}) => MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: trips),
            ChangeNotifierProvider.value(value: places),
            ChangeNotifierProvider.value(value: alerts),
            Provider<AlertScheduler>.value(value: _NoScheduler()),
          ],
          child: SnowBirdApp(deviceAuth: auth),
        );
    await settings.setLocale(const Locale('en'));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('New: days by place'), findsOneWidget);
    await shot(tester, 'en_01_upgrade_note');
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    final saved = jsonDecode(prefs.getString('snowbird.trips.v1')!) as Map;
    expect(saved['schemaVersion'], 2, reason: 'reading alone writes nothing');

    // EN: 2. A traveller's year: Florida, then Ontario and Yukon with days
    //     worked, a day visit to Quebec, a home base in Ontario, a planned
    //     stay in Mexico.
    // FR: 2. Une année de voyageur : la Floride, puis l'Ontario et le Yukon
    //     avec des jours travaillés, une visite d'un jour au Québec, un
    //     domicile en Ontario, un séjour planifié au Mexique.
    await trips.addTrip(
      Trip.create(
        arrivalDate: _ago(150),
        departureDate: _ago(60),
        status: TripStatus.actual,
        place: Place.parse('CA-ON'),
        work: WorkPlan(weekdays: const {1, 2, 3, 4, 5}),
        purpose: StayPurpose.work,
        label: 'Greenhouse',
        notes: 'Seasonal contract',
      ),
    );
    await trips.addTrip(
      Trip.create(
        arrivalDate: _ago(60),
        departureDate: null,
        status: TripStatus.actual,
        place: Place.parse('CA-YT'),
        work: WorkPlan(weekdays: const {2, 3, 4, 5, 6}),
      ),
    );
    await trips.addTrip(
      Trip.create(
        arrivalDate: _ago(-30),
        departureDate: _ago(-60),
        status: TripStatus.planned,
        place: Place.parse('MX-SON'),
      ),
    );
    await trips.addVisit(
      DayVisit.create(
        date: _ago(100),
        place: Place.parse('CA-QC'),
        worked: true,
      ),
    );
    await places.addHomePeriod(
      HomePeriod(place: Place.parse('CA-ON'), from: DateTime(2020)),
    );
    await places.setWorkEnabled(true);
    await places.setExpanded(Place.canada, true);
    await tester.pumpAndSettle();

    final ontario =
        trips.trips.firstWhere((t) => t.place == Place.parse('CA-ON'));
    final screens = <String, Widget>{
      '03_stay_edit': TripEditScreen(existing: ontario),
      '04_place_picker': PlacePickerScreen(recent: trips.recentPlaces()),
      '05_explore': const ExploreScreen(),
      '06_alert_edit': const AlertEditScreen(),
      '07_places_settings': const PlacesSettingsScreen(),
      '08_export': const ExportScreen(),
      '09_reference': const ReferenceScreen(),
      '10_visits': const VisitsScreen(),
      '11_work_calendar': WorkCalendarScreen(
        from: ontario.arrivalDate,
        to: ontario.departureDate!,
        plan: ontario.work!,
      ),
      '12_split': SplitStayScreen(stay: ontario),
      '13_settings': const SettingsScreen(),
    };
    NavigatorState nav() =>
        tester.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> walk(String prefix) async {
      await shot(tester, '${prefix}_02_main');
      for (final entry in screens.entries) {
        nav()
            .push(MaterialPageRoute<void>(builder: (_) => entry.value))
            .ignore();
        await tester.pumpAndSettle();
        await shot(tester, '${prefix}_${entry.key}');
        nav().pop();
        await tester.pumpAndSettle();
      }
    }

    await walk('en');
    await settings.setLocale(const Locale('fr'));
    await tester.pumpAndSettle();
    await walk('fr');

    // EN: The hardest case: largest app text, dark, high contrast.
    // FR: Le cas le plus difficile : plus grand texte de l'appli, sombre,
    //     contraste élevé.
    await settings.setLocale(const Locale('en'));
    await settings.setTextScale(1.6);
    await settings.setThemeMode(ThemeMode.dark);
    await settings.setHighContrast(true);
    await tester.pumpAndSettle();
    await shot(tester, 'big_02_main');
    for (final key in ['03_stay_edit', '05_explore', '08_export']) {
      nav()
          .push(MaterialPageRoute<void>(builder: (_) => screens[key]!))
          .ignore();
      await tester.pumpAndSettle();
      await shot(tester, 'big_$key');
      nav().pop();
      await tester.pumpAndSettle();
    }
    await settings.setTextScale(1.0);
    await settings.setThemeMode(ThemeMode.light);
    await settings.setHighContrast(false);

    // EN: 3. The exports, built as the export screen builds them.
    // FR: 3. Les exports, construits comme les construit l'écran d'export.
    for (final locale in ['en', 'fr']) {
      final strings = lookupAppLocalizations(Locale(locale));
      for (final (scope, name) in <(Place?, String)>[
        (null, 'all'),
        (Place.unitedStates, 'us'),
      ]) {
        final record = PresenceRecord.build(
          trips: trips.trips,
          visits: trips.visits,
          scope: scope,
          tracked: places.tracked,
          home: places.home,
          includeWork: scope == null,
        );
        final pdf = await RecordExporter.buildPdf(
          record,
          strings: strings,
          localeName: locale,
        );
        files['record_${name}_$locale.pdf'] = base64Encode(pdf);
        var page = 0;
        await for (final raster in Printing.raster(pdf, dpi: 110)) {
          page++;
          files['record_${name}_${locale}_page$page.png'] =
              base64Encode(await raster.toPng());
        }
        files['record_${name}_$locale.txt'] = base64Encode(
          utf8.encode(
            buildRecordText(record, strings: strings, localeName: locale),
          ),
        );
        if (locale == 'en') {
          files['record_$name.csv'] = base64Encode(utf8.encode(record.toCsv()));
          files['record_${name}_by_day.csv'] =
              base64Encode(utf8.encode(record.toLedgerCsv()));
        }
      }
    }

    // EN: 4. The lock screen, with a check that does not pass.
    // FR: 4. L'écran de verrouillage, avec une vérification qui échoue.
    await settings.setAppLock(true);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(auth: const _Auth(false)));
    await tester.pumpAndSettle();
    expect(find.text('SENALOVIRA is locked'), findsOneWidget);
    await shot(tester, 'en_14_lock');
    await settings.setAppLock(false);

    // EN: Merge, never replace: takeScreenshot keeps its images in the same
    //     report, under "screenshots".
    // FR: Fusionner, jamais remplacer : takeScreenshot garde ses images dans
    //     le même rapport, sous « screenshots ».
    binding.reportData = {...?binding.reportData, ...files};
    await prefs.clear();
  });
}
