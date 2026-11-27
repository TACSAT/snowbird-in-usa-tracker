// EN: Widget tests for days worked (section 7 and section 18): nothing about
//     work appears anywhere while it is off; once on, a weekday pattern and a
//     calendar correction are saved, and the table shows days worked as a
//     second line, never summed with presence.
// FR: Tests d'interface des jours travaillés (sections 7 et 18) : rien de
//     relatif au travail n'apparaît nulle part tant que c'est désactivé ; une
//     fois activé, un motif de jours et une correction au calendrier sont
//     enregistrés, et le tableau montre les jours travaillés en seconde ligne,
//     jamais additionnés à la présence.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/visits_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class _App {
  late StorageService storage;
  late TripRepository trips;
  late PresenceSettings settings;
}

Widget _wrap(_App app, Widget home) => MultiProvider(
      providers: [
        Provider<StorageService>.value(value: app.storage),
        ChangeNotifierProvider<TripRepository>.value(value: app.trips),
        ChangeNotifierProvider<PresenceSettings>.value(value: app.settings),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Future<_App> _start(
  WidgetTester tester, {
  required bool work,
  List<Trip> stays = const [],
  Widget home = const TripListScreen(),
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'snowbird.flags.disclaimerAck.v1': true,
    'snowbird.flags.backupReminderShown.v1': true,
    'snowbird.settings.workEnabled.v1': work,
  });
  final app = _App()
    ..storage = StorageService(await SharedPreferences.getInstance());
  app
    ..trips = TripRepository(app.storage)
    ..settings = PresenceSettings(app.storage);
  for (final stay in stays) {
    await app.trips.addTrip(stay);
  }
  await tester.pumpWidget(_wrap(app, home));
  await tester.pumpAndSettle();
  return app;
}

// EN: A closed stay of two full weeks, Monday 2 to Sunday 15 March 2026.
// FR: Un séjour fermé de deux semaines pleines, du lundi 2 au dimanche 15
//     mars 2026.
Trip _march() => Trip.create(
      arrivalDate: DateTime(2026, 3, 2),
      departureDate: DateTime(2026, 3, 15),
      status: TripStatus.actual,
      place: Place.parse('CA-ON'),
    );

void main() {
  testWidgets('with work off, no work field or figure exists (section 18)',
      (tester) async {
    final stay = _march();
    final app = await _start(tester, work: false, stays: [stay]);
    expect(find.textContaining('Worked'), findsNothing);
    for (final screen in [
      TripEditScreen(existing: stay),
      const VisitEditScreen(),
    ]) {
      await tester.pumpWidget(_wrap(app, screen));
      await tester.pumpAndSettle();
      expect(find.text('Days worked'), findsNothing);
      expect(find.text('Usually worked on'), findsNothing);
      expect(find.text('Worked there that day'), findsNothing);
      expect(find.text('Purpose of this stay'), findsNothing);
      expect(find.text('Job or contract (optional)'), findsNothing);
    }
  });

  testWidgets('a pattern and a correction are saved; the table shows them',
      (tester) async {
    final stay = _march();
    final app = await _start(
      tester,
      work: true,
      stays: [stay],
      home: TripEditScreen(existing: stay),
    );
    expect(find.text('Days worked'), findsOneWidget);
    expect(find.text('No days worked so far'), findsOneWidget);
    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']) {
      await tester.tap(find.text(day));
      await tester.pumpAndSettle();
    }
    expect(find.text('10 days worked'), findsOneWidget);

    await tester.tap(find.text('Correct single days'));
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    final saturday = find.bySemanticsLabel(
      'Saturday, March 7, 2026: not worked',
    );
    expect(saturday, findsOneWidget);
    await tester.tap(saturday);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Saturday, March 7, 2026: worked'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('March 16, 2026')),
      findsNothing,
      reason: 'days outside the stay cannot be marked',
    );
    handle.dispose();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('11 days worked'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.trips.trips.single.work?.weekdays, {1, 2, 3, 4, 5});
    expect(app.trips.trips.single.work?.added, {DateTime(2026, 3, 7)});

    // EN: The table: presence and work are two lines, two figures each.
    // FR: Le tableau : présence et travail sont deux lignes, deux chiffres
    //     chacune.
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_wrap(app, const TripListScreen()));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final inYear = now.year == 2026 ? '14 days' : '0 days';
    final workedYear = now.year == 2026 ? '11 days' : '0 days';
    final row = find.bySemanticsLabel(RegExp('^Canada: $inYear'));
    expect(row, findsOneWidget);
    expect(
      tester.getSemantics(row).label,
      contains('worked: $workedYear this calendar year'),
    );
    expect(find.text('Worked'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('a day visit can be marked as worked', (tester) async {
    final app = await _start(tester, work: true, home: const VisitEditScreen());
    await tester.tap(find.text('Place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quebec'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Worked there that day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(app.trips.visits.single.worked, isTrue);
  });
}
