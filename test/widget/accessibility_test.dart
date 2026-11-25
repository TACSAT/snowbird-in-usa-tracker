// EN: Every screen, at large text on a small phone, in both languages, must lay out
//     without overflow and stay usable (NFR-5): the primary user is an older adult.
//     Also pins inline errors, clearable times and the permission order.
// FR: Chaque écran, en grand texte sur un petit téléphone, dans les deux langues,
//     doit se mettre en page sans débordement et rester utilisable (NFR-5) :
//     l'utilisateur principal est une personne âgée. Verrouille aussi les erreurs en
//     ligne, les heures effaçables et l'ordre de la permission.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/app.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/about_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/explore_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/labeled_field.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/value_row.dart';
import 'package:snowbird_in_usa_tracker/services/alert_scheduler.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/alert_repository.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class _Scheduler implements AlertScheduler {
  _Scheduler({this.granted = true});
  final bool granted;
  final log = <String>[];
  @override
  Future<bool> ensurePermissions() async {
    log.add('permission');
    return granted;
  }

  @override
  Future<void> reschedule(List<ScheduledAlert> schedule) async =>
      log.add('schedule');
}

class _App {
  late final TripRepository trips;
  late final AlertRepository alerts;
  late final _Scheduler scheduler;
}

Future<_App> _start(
  WidgetTester tester, {
  Size size = const Size(320, 568),
  double os = 1,
  double app = 1,
  String locale = 'en',
  bool granted = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = os;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  SharedPreferences.setMockInitialValues({
    'snowbird.flags.disclaimerAck.v1': true,
    'snowbird.flags.backupReminderShown.v1': true,
    'snowbird.settings.textScale.v1': app,
    'snowbird.settings.locale.v1': locale,
  });
  PackageInfo.setMockInitialValues(
    appName: 'SnowBird',
    packageName: 'x',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final storage = StorageService(await SharedPreferences.getInstance());
  final result = _App()..scheduler = _Scheduler(granted: granted);
  result.trips = TripRepository(storage);
  result.alerts = AlertRepository(
    storage,
    result.trips,
    scheduler: result.scheduler,
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider.value(value: SettingsController(storage)),
        ChangeNotifierProvider.value(value: result.trips),
        ChangeNotifierProvider.value(value: result.alerts),
        Provider<AlertScheduler>.value(value: result.scheduler),
      ],
      child: const SnowBirdApp(),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

Future<void> _open(WidgetTester tester, Widget screen) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => screen))
      .ignore();
  await tester.pumpAndSettle();
}

// EN: Text cut off by "..." on the current screen. App bar titles are exempt: one line
//     by platform convention, and they repeat what the user just tapped.
// FR: Textes coupés par « … » à l'écran. Les titres de barre sont exemptés : une ligne
//     par convention, et ils répètent ce que l'utilisateur vient de toucher.
List<String> _truncated(WidgetTester tester) {
  final found = <String>[];
  void visit(RenderObject node, bool inBar) {
    if (node is RenderParagraph && !inBar && node.didExceedMaxLines) {
      found.add(node.text.toPlainText());
    }
    node.visitChildren((c) => visit(c, inBar));
  }

  for (final e in find.byType(Scrollable).evaluate()) {
    visit(e.renderObject!, false);
  }
  return found;
}

void main() {
  final today = DateTime.now();
  final openTrip = Trip.create(
    arrivalDate: DateTime(today.year, today.month, today.day - 2),
    departureDate: null,
    status: TripStatus.actual,
    name: 'Winter in Hallandale Beach',
    arrivalInfo: const CrossingInfo(timeMinutes: 870),
  );

  for (final locale in ['en', 'fr']) {
    for (final (os, app) in [(1.0, 1.0), (1.5, 1.6), (2.0, 1.6), (3.1, 1.0)]) {
      testWidgets('all screens fit: $locale os=$os app=$app', (tester) async {
        final a = await _start(tester, os: os, app: app, locale: locale);
        await a.trips.addTrip(openTrip);
        await a.trips.addTrip(
          Trip.create(
            arrivalDate: DateTime(2025, 1, 1),
            departureDate: DateTime(2025, 12, 31),
            status: TripStatus.planned,
          ),
        );
        final alert = DayAlert.create(
          thresholdDays: 120,
          windowDays: 365,
          hour: 9,
          minute: 0,
          label: 'Provincial coverage',
        );
        await a.alerts.addAlert(alert);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'list');

        for (final screen in [
          const TripEditScreen(),
          TripEditScreen(existing: openTrip),
          const ExploreScreen(),
          const AlertsScreen(),
          const AlertEditScreen(),
          AlertEditScreen(existing: alert),
          const SettingsScreen(),
          const ReferenceScreen(),
          const AboutScreen(),
        ]) {
          await _open(tester, screen);
          final sections = find.byType(ExpansionTile);
          for (var i = sections.evaluate().length - 1; i >= 0; i--) {
            await tester.ensureVisible(sections.at(i));
            await tester.pumpAndSettle();
            await tester.tap(
              find
                  .descendant(
                    of: sections.at(i),
                    matching: find.byType(ListTile),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
          }
          expect(
            _truncated(tester),
            isEmpty,
            reason: '${screen.runtimeType} cuts text off',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType}',
          );
          // EN: Walk the whole screen so lazily-built parts are laid out too.
          // FR: Parcourir tout l'écran pour que les parties construites à la
          //     demande soient aussi mises en page.
          for (var i = 0; i < 12; i++) {
            await tester.drag(
              find.byType(Scrollable).hitTestable().first,
              const Offset(0, -300),
              warnIfMissed: false,
            );
            await tester.pump();
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} scrolled',
          );
        }
      });

      testWidgets('trips are reachable: $locale os=$os app=$app',
          (tester) async {
        final a = await _start(tester, os: os, app: app, locale: locale);
        await a.trips.addTrip(openTrip);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Winter in Hallandale Beach'),
          100,
        );
        await tester.ensureVisible(find.text('Winter in Hallandale Beach'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Winter in Hallandale Beach'));
        await tester.pumpAndSettle();
        expect(find.byType(TripEditScreen), findsOneWidget);
      });
    }
  }

  for (final (os, app, expected) in [
    (1.0, 1.0, 1.0),
    (1.0, 1.6, 1.6),
    (1.5, 1.6, 2.0),
    (3.0, 1.6, 3.0),
    (2.0, 0.85, 1.7),
  ]) {
    testWidgets('text scale os=$os app=$app gives $expected', (tester) async {
      await _start(tester, os: os, app: app);
      final context = tester.element(find.byType(TripListScreen));
      expect(MediaQuery.textScalerOf(context).scale(10), expected * 10);
    });
  }

  testWidgets('date errors are inline, visible, and clear on correction',
      (tester) async {
    await _start(tester);
    await _open(tester, const TripEditScreen());
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Select an arrival date.').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Arrival date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Select an arrival date.'), findsNothing);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Select a departure date.').hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('an optional crossing time can be cleared', (tester) async {
    final a = await _start(tester, size: const Size(800, 1600));
    await a.trips.addTrip(openTrip);
    await _open(tester, TripEditScreen(existing: openTrip));
    await tester.tap(find.text('Entry crossing (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear time'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear time'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(a.trips.trips.single.arrivalInfo, isNull);
  });

  Future<void> fillAlert(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(LabeledField, 'Notify me at this many days'),
      '30',
    );
    await tester.enterText(
      find.widgetWithText(LabeledField, 'Counted within the last (days)'),
      '365',
    );
    await tester.tap(find.text('Delivery time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('permission is asked before the first schedule', (tester) async {
    final a = await _start(tester, size: const Size(800, 1600));
    await _open(tester, const AlertEditScreen());
    await fillAlert(tester);
    a.scheduler.log.clear();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(a.scheduler.log, ['permission', 'schedule']);
    expect(a.alerts.alertCount, 1);
  });

  testWidgets('a refused permission keeps the alert and says so',
      (tester) async {
    final a = await _start(
      tester,
      size: const Size(800, 1600),
      granted: false,
    );
    await _open(tester, const AlertEditScreen());
    await fillAlert(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(a.alerts.alertCount, 1);
    expect(find.textContaining('Notifications are turned off'), findsOneWidget);
  });

  testWidgets('an inactive alert asks for nothing until it is switched on',
      (tester) async {
    final a = await _start(tester, size: const Size(800, 1600));
    await _open(tester, const AlertsScreen());
    await _open(tester, const AlertEditScreen());
    await fillAlert(tester);
    await tester.tap(find.text('Active'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(a.scheduler.log, isNot(contains('permission')));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(a.scheduler.log.indexOf('permission'), greaterThanOrEqualTo(0));
    expect(a.alerts.alerts.single.enabled, isTrue);
  });

  testWidgets('a missing delivery time and an off-screen field are caught',
      (tester) async {
    final a = await _start(tester);
    await _open(tester, const AlertEditScreen());
    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(a.alerts.alertCount, 0);
    expect(find.text('Choose a delivery time.'), findsOneWidget);
  });

  testWidgets('a missing delivery time alone blocks saving', (tester) async {
    final a = await _start(tester, size: const Size(800, 1600));
    await _open(tester, const AlertEditScreen());
    for (final (field, value) in [
      ('Notify me at this many days', '30'),
      ('Counted within the last (days)', '365'),
    ]) {
      await tester.enterText(find.widgetWithText(LabeledField, field), value);
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Choose a delivery time.'), findsOneWidget);
    expect(a.alerts.alertCount, 0);
  });

  for (final locale in ['en', 'fr']) {
    testWidgets('filled what-if fits at the largest text: $locale',
        (tester) async {
      final a = await _start(tester, os: 3.1, locale: locale);
      await a.trips.addTrip(openTrip);
      await _open(tester, const ExploreScreen());
      final list = find.byType(Scrollable).last;
      for (final label in locale == 'en'
          ? ['Possible arrival', 'Possible departure']
          : ['Arrivée possible', 'Départ possible']) {
        await tester.scrollUntilVisible(
          find.text(label),
          200,
          scrollable: list,
        );
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      final save = find.byType(FilledButton);
      await tester.scrollUntilVisible(save, 200, scrollable: list);
      expect(tester.takeException(), isNull);
      expect(save, findsOneWidget);
    });
  }

  for (final locale in ['en', 'fr']) {
    for (final os in [1.0, 2.0, 3.1]) {
      testWidgets('date and time dialogs fit: $locale os=$os', (tester) async {
        final a = await _start(tester, os: os, locale: locale);
        await a.trips.addTrip(openTrip);
        for (final (screen, index) in <(Widget, int)>[
          (TripEditScreen(existing: openTrip), 0),
          (const AlertEditScreen(), 0),
        ]) {
          await _open(tester, screen);
          final row = find.byType(ValueRow).at(index);
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          await tester.tap(
            find.descendant(of: row, matching: find.byType(ListTile)),
          );
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType}',
          );
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
        }
      });
    }
  }

  testWidgets('every field keeps its label for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _start(tester, size: const Size(800, 1600));
    await _open(tester, const AlertEditScreen());
    final fields = find.byType(LabeledField);
    expect(fields, findsNWidgets(5));
    for (var i = 0; i < 5; i++) {
      final widget = tester.widget<LabeledField>(fields.at(i));
      final node = tester.getSemantics(
        find.descendant(of: fields.at(i), matching: find.byType(EditableText)),
      );
      expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
      expect(node.label, contains(widget.label));
    }
    handle.dispose();
  });

  testWidgets('a trip from decades ago can be opened and its date picked',
      (tester) async {
    final a = await _start(tester, size: const Size(800, 1600));
    for (final year in [1940, 1995]) {
      final old = Trip.create(
        arrivalDate: DateTime(year, 1, 5),
        departureDate: DateTime(year, 1, 9),
        status: TripStatus.actual,
      );
      await a.trips.addTrip(old);
      await _open(tester, TripEditScreen(existing: old));
      await tester.tap(find.text('Arrival date'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('January 5, $year'), findsOneWidget);
    }
  });

  testWidgets('the arrival picker reaches well past ten years back',
      (tester) async {
    await _start(tester, size: const Size(800, 1600));
    await _open(tester, const TripEditScreen());
    await tester.tap(find.text('Arrival date'));
    await tester.pumpAndSettle();
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(dialog.firstDate.year, lessThanOrEqualTo(1970));
  });

  for (final locale in ['en', 'fr']) {
    testWidgets(
        'the export sheet fits and scrolls at the largest text: $locale',
        (tester) async {
      final a = await _start(tester, os: 3.1, locale: locale);
      await a.trips.addTrip(openTrip);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_truncated(tester), isEmpty);
      final last = find.byIcon(Icons.print_outlined);
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(last.hitTestable(), findsOneWidget);
    });
  }
}
