// EN: What VoiceOver and TalkBack are given to say. Guideline checks cover every screen
//     in both themes and languages; the rest pins names, headings, reading units and
//     announcements. It cannot judge how the app sounds: that needs a person.
// FR: Ce que VoiceOver et TalkBack ont à lire. Les vérifications couvrent chaque écran
//     dans les deux thèmes et langues ; le reste verrouille noms, titres, unités de
//     lecture et annonces. Elles ne jugent pas l'écoute : il faut une personne.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/screens/export_screen.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';
import 'package:snowbird_in_usa_tracker/screens/work_calendar_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/places_settings_screen.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/split_stay_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/visits_screen.dart';
import 'package:snowbird_in_usa_tracker/app.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/day_alert.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/about_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/explore_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/reference_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
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
  bool highContrast = false,
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
    'snowbird.settings.highContrast.v1': highContrast,
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
        ChangeNotifierProvider.value(value: PresenceSettings(storage)),
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

// EN: The items a screen reader stops on, in order. Nodes merged into a parent are
//     skipped: they are not separate stops.
// FR: Les éléments où s'arrête un lecteur d'écran, dans l'ordre. Les nœuds fusionnés
//     dans un parent sont sautés : ce ne sont pas des arrêts distincts.
List<SemanticsData> _stops(WidgetTester tester) {
  final result = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (node.isMergedIntoParent) return;
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty || data.value.isNotEmpty) result.add(data);
    node
        .debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)
        .forEach(visit);
  }

  visit(tester.getSemantics(find.byType(Navigator).first));
  return result;
}

SemanticsData _stop(WidgetTester tester, Pattern label) =>
    _stops(tester).singleWhere((d) => d.label.contains(label));

List<String> _headings(WidgetTester tester) => [
      for (final d in _stops(tester))
        if (d.flagsCollection.isHeader) d.label,
    ];

// EN: Texts below WCAG AA contrast. Flutter's own check guesses the text colour from
//     anti-aliased pixels, which differ by platform and by line wrapping. Here the text
//     colour is the declared one, and the background is the most common pixel around it.
//     Only the front route counts: what lies under a sheet is dimmed on purpose. Icons
//     are skipped: each one here accompanies a text or a named control.
// FR: Textes sous le contraste WCAG AA. La vérification de Flutter devine la couleur du
//     texte à partir de pixels lissés, qui varient selon la plateforme et les retours à
//     la ligne. Ici la couleur du texte est celle déclarée, et le fond est le pixel le
//     plus fréquent autour. Seul l'écran de devant compte : ce qui est sous une feuille
//     est assombri à dessein. Les icônes sont omises : chacune accompagne un texte ou un
//     contrôle nommé.
Future<List<String>> _lowContrast(
  WidgetTester tester, {
  double normal = 4.5,
  double large = 3,
}) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  late ByteData pixels;
  late int width;
  late int height;
  await tester.runAsync(() async {
    final image = await layer.toImage(view.paintBounds);
    width = image.width;
    height = image.height;
    pixels = (await image.toByteData())!;
    image.dispose();
  });

  final found = <String>[];
  var checked = 0;
  void check(Element element, String text, TextStyle? style) {
    final color = style?.color;
    if (text.trim().isEmpty || color == null) return;
    if (style!.fontFamily == 'MaterialIcons') return;
    if (!(ModalRoute.of(element)?.isCurrent ?? true)) return;
    final box = element.renderObject! as RenderBox;
    final rect = (box.localToGlobal(Offset.zero) & box.size)
        .inflate(2)
        .intersect(Offset.zero & Size(width.toDouble(), height.toDouble()));
    if (rect.isEmpty) return;
    final counts = <int, int>{};
    for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
      for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
        final rgba = pixels.getUint32((y * width + x) * 4);
        counts[rgba] = (counts[rgba] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return;
    final rgba =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final back = Color(0xFF000000 | (rgba >> 8));
    final a = Color.alphaBlend(color, back).computeLuminance();
    final b = back.computeLuminance();
    final ratio = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
    final size = style.fontSize ?? 14;
    final bold = (style.fontWeight ?? FontWeight.normal).value >= 700;
    final needed = size >= 24 || bold && size >= 18.66 ? large : normal;
    checked++;
    if (ratio < needed) found.add('"$text" ${ratio.toStringAsFixed(2)}');
  }

  for (final e in find.byType(RichText).evaluate()) {
    final span = (e.widget as RichText).text;
    check(e, span.toPlainText(), span.style);
  }
  for (final e in find.byType(EditableText).evaluate()) {
    final w = e.widget as EditableText;
    check(e, w.controller.text, w.style);
  }
  // EN: A check that looked at nothing must not pass.
  // FR: Une vérification qui n'a rien regardé ne doit pas réussir.
  expect(checked, greaterThan(2));
  return found;
}

void main() {
  final now = DateTime.now();
  final openTrip = Trip.create(
    arrivalDate: DateTime(now.year, now.month, now.day - 2),
    departureDate: null,
    status: TripStatus.actual,
    name: 'Winter',
    arrivalInfo: const CrossingInfo(timeMinutes: 870),
  );
  final planned = Trip.create(
    arrivalDate: DateTime(now.year + 1),
    departureDate: DateTime(now.year + 1, 1, 9),
    status: TripStatus.planned,
  );
  DayAlert alert({String? label}) => DayAlert.create(
        thresholdDays: 120,
        windowDays: 365,
        hour: 9,
        minute: 0,
        label: label,
      );
  const tall = Size(390, 2400);

  setUpAll(() async {
    // EN: Real glyphs, so contrast is measured on text rather than on test blocks.
    // FR: De vrais glyphes, pour mesurer le contraste sur du texte et non des blocs.
    final font = File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync();
    await (FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(font))))
        .load();
  });

  for (final locale in ['en', 'fr']) {
    for (final (brightness, high) in [
      for (final b in Brightness.values)
        for (final h in [false, true]) (b, h),
    ]) {
      final mode = '${brightness.name}${high ? ' high contrast' : ''}';
      testWidgets('guidelines: $locale $mode', (tester) async {
        final handle = tester.ensureSemantics();
        final a = await _start(
          tester,
          size: tall,
          locale: locale,
          highContrast: high,
        );
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        await a.trips.addTrip(openTrip);
        await a.trips.addTrip(planned);
        await a.alerts.addAlert(alert());
        await tester.pumpAndSettle();

        Future<void> check() async {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          // EN: High contrast is held to WCAG AAA, the ordinary themes to AA.
          // FR: Le contraste élevé vise WCAG AAA, les thèmes ordinaires AA.
          expect(
            high
                ? await _lowContrast(tester, normal: 7, large: 4.5)
                : await _lowContrast(tester),
            isEmpty,
          );
          // EN: Adjustable controls are not "tap targets", so check them here.
          // FR: Les contrôles réglables ne sont pas des cibles à toucher ; les
          //     vérifier ici.
          for (final d in _stops(tester)) {
            if (d.flagsCollection.isSlider) expect(d.label, isNotEmpty);
          }
        }

        await check();
        await tester.tap(find.byIcon(Icons.ios_share_rounded));
        await tester.pumpAndSettle();
        await check();
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        for (final screen in [
          TripEditScreen(existing: openTrip),
          const TripEditScreen(),
          const ExploreScreen(),
          const AlertsScreen(),
          const AlertEditScreen(),
          const SettingsScreen(),
          const ReferenceScreen(),
          const AboutScreen(),
          PlacePickerScreen(recent: [Place.parse('CA-ON'), Place.mexico]),
          SplitStayScreen(stay: openTrip),
          const VisitsScreen(),
          const VisitEditScreen(),
          const PlacesSettingsScreen(),
          const ExportScreen(),
          WorkCalendarScreen(
            from: DateTime(2026, 3, 2),
            to: DateTime(2026, 4, 15),
            plan: WorkPlan(weekdays: const {1, 2, 3, 4, 5}),
          ),
        ]) {
          await _open(tester, screen);
          final sections = find.byType(ExpansionTile);
          if (sections.evaluate().isNotEmpty) {
            await tester.tap(
              find
                  .descendant(
                    of: sections.first,
                    matching: find.byType(ListTile),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
          }
          final save = find.byType(FilledButton);
          if (screen is AlertEditScreen ||
              screen is TripEditScreen && screen.existing == null) {
            await tester.tap(save);
            await tester.pumpAndSettle();
          }
          await check();
        }
        handle.dispose();
      });
    }
  }

  testWidgets('each alert switch says which alert it controls', (tester) async {
    final handle = tester.ensureSemantics();
    final a = await _start(tester, size: tall);
    await a.alerts.addAlert(alert(label: 'Coverage'));
    await a.alerts.addAlert(alert());
    await _open(tester, const AlertsScreen());
    final switches = [
      for (final d in _stops(tester))
        if (d.flagsCollection.isToggled != Tristate.none) d.label,
    ];
    expect(switches, hasLength(2));
    expect(switches.toSet(), hasLength(2));
    expect(switches, anyElement(contains('Coverage')));
    expect(switches, anyElement(contains('120 days')));
    handle.dispose();
  });

  testWidgets('the text-size slider has a name and its real size',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _start(tester, size: tall);
    await _open(tester, const SettingsScreen());
    final slider =
        _stops(tester).singleWhere((d) => d.flagsCollection.isSlider);
    expect(slider.label, 'Text size in this app');
    expect(slider.value, '100%');
    expect(slider.increasedValue, '120%');
    expect(slider.decreasedValue, '85%');
    handle.dispose();
  });

  // EN: The Days present table is one stop per place, with both figures in
  //     its label (TBL-10).
  // FR: Le tableau des jours de présence est un arrêt par lieu, avec les deux
  //     chiffres dans son libellé (TBL-10).
  testWidgets('each table row is its own stop; SPT is a button',
      (tester) async {
    final handle = tester.ensureSemantics();
    final a = await _start(tester, size: tall);
    await a.trips.addTrip(openTrip);
    await tester.pumpAndSettle();
    expect(
      _stop(tester, 'United States:').label,
      'United States: 3 days this calendar year, '
      '3 days in the last 365 days',
    );
    expect(
      _stop(tester, 'Not recorded').label,
      startsWith('Not recorded: '),
    );
    final spt = _stop(tester, 'Substantial Presence');
    expect(spt.flagsCollection.isButton, isTrue);
    expect(spt.hasAction(SemanticsAction.tap), isTrue);
    expect(spt.label, contains('3'));
    expect(_headings(tester), contains('Days present'));
    handle.dispose();
  });

  testWidgets('a trip is one stop with its status, its dates said once',
      (tester) async {
    final handle = tester.ensureSemantics();
    final a = await _start(tester, size: tall);
    await a.trips.addTrip(openTrip);
    await a.trips.addTrip(planned);
    await tester.pumpAndSettle();
    final unnamed = _stop(tester, 'Planned');
    expect(unnamed.hasAction(SemanticsAction.tap), isTrue);
    expect('Jan 1'.allMatches(unnamed.label), hasLength(1));
    expect(unnamed.label, contains('9 days'));
    final named = _stop(tester, 'Winter');
    expect(named.label, contains('Current'));
    expect(named.label, contains('3 days so far'));
    handle.dispose();
  });

  testWidgets('sections are headings on every screen that has them',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _start(tester, size: tall);
    for (final (screen, expected) in <(Widget, List<String>)>[
      (
        const ExploreScreen(),
        ['Days in a period', 'What if I take this trip?'],
      ),
      (const AlertEditScreen(), ['What to watch', 'Advance notice']),
      (const TripEditScreen(), ['Trip type']),
      (
        const SettingsScreen(),
        ['Language', 'Appearance', 'Text size in this app'],
      ),
      (
        const ReferenceScreen(),
        [
          'US Substantial Presence Test',
          'Provincial health coverage',
          'Length of a US visit',
          'There is no single cumulative limit',
        ],
      ),
      (const AboutScreen(), ['Your privacy']),
    ]) {
      await _open(tester, screen);
      expect(
        _headings(tester),
        containsAll(expected),
        reason: '${screen.runtimeType}',
      );
    }
    handle.dispose();
  });

  testWidgets('an unset alert time is said in words', (tester) async {
    final handle = tester.ensureSemantics();
    await _start(tester, size: tall);
    await _open(tester, const AlertEditScreen());
    expect(_stop(tester, 'Delivery time').label, contains('Not set'));
    handle.dispose();
  });

  testWidgets('changed counts and what-if results are announced',
      (tester) async {
    final handle = tester.ensureSemantics();
    final a = await _start(tester, size: tall);
    await a.trips.addTrip(openTrip);
    await _open(tester, const ExploreScreen());
    final range = _stop(tester, 'Actual days so far');
    expect(range.flagsCollection.isLiveRegion, isTrue);
    expect(range.label, contains('Including planned trips'));
    for (final label in ['Possible arrival', 'Possible departure']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }
    final live = [
      for (final d in _stops(tester))
        if (d.flagsCollection.isLiveRegion) d.label,
    ];
    // EN: One figure only: announcing all six would talk over the user.
    // FR: Un seul nombre : annoncer les six couvrirait l'utilisateur.
    expect(live, hasLength(2));
    expect(live.last, contains('365 days ending'));
    expect(live.last, contains('With this trip'));
    handle.dispose();
  });

  test('iOS declares both languages', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      matches(
        RegExp(
          r'CFBundleLocalizations</key>\s*<array>\s*<string>en</string>'
          r'\s*<string>fr</string>',
        ),
      ),
    );
  });

  testWidgets('the contrast check itself catches faint text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('faint', style: TextStyle(color: Color(0xFFBBBBBB))),
              Text('clear', style: TextStyle(color: Color(0xFF000000))),
              Text(
                'large',
                style: TextStyle(color: Color(0xFF888888), fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
    final found = await _lowContrast(tester);
    expect(found.single, startsWith('"faint"'));
  });
}
