// EN: Widget tests for the Days present table and the Places and home screen
//     (REQUIREMENTS-places.md sections 6, 9 and 12): expanding a country and
//     remembering it, choosing places and conventions, adding a home base, and
//     the one-time upgrade note.
// FR: Tests d'interface du tableau des jours de présence et de l'écran Lieux et
//     domicile (REQUIREMENTS-places.md, sections 6, 9 et 12) : déplier un pays et
//     s'en souvenir, choisir les lieux et les conventions, ajouter un domicile,
//     et la note unique après mise à jour.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/places_settings_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

const _onboarded = {
  'snowbird.flags.disclaimerAck.v1': true,
  'snowbird.flags.backupReminderShown.v1': true,
};

class _App {
  late StorageService storage;
  late TripRepository trips;
  late PresenceSettings settings;
}

Future<_App> _start(
  WidgetTester tester, {
  Map<String, Object> prefs = _onboarded,
  List<Trip> stays = const [],
  Widget home = const TripListScreen(),
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
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

DateTime _daysAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - n);
}

Trip _stay(Place place, int fromDaysAgo, int? toDaysAgo) => Trip.create(
      arrivalDate: _daysAgo(fromDaysAgo),
      departureDate: toDaysAgo == null ? null : _daysAgo(toDaysAgo),
      status: TripStatus.actual,
      place: place,
    );

final _canadian = [
  _stay(Place.parse('CA-ON'), 60, 40),
  _stay(Place.parse('CA-YT'), 40, null),
];

void main() {
  testWidgets('a country expands to its regions, and stays expanded',
      (tester) async {
    final handle = tester.ensureSemantics();
    final app = await _start(tester, stays: _canadian);
    expect(find.text('Canada'), findsOneWidget);
    expect(find.text('Now: Yukon, Canada, 41 days'), findsOneWidget);
    expect(find.text('Yukon'), findsNothing, reason: 'collapsed by default');
    final row = find.bySemanticsLabel(RegExp(r'^Canada: \d+ days'));
    expect(tester.getSemantics(row).flagsCollection.isButton, isTrue);

    await tester.tap(find.text('Canada'));
    await tester.pumpAndSettle();
    expect(find.text('Yukon'), findsOneWidget);
    expect(find.text('Ontario'), findsOneWidget);
    expect(app.settings.isExpanded(Place.canada), isTrue);

    app.settings = PresenceSettings(app.storage);
    await tester.pumpWidget(_wrap(app, const TripListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Yukon'), findsOneWidget, reason: 'remembered');
    handle.dispose();
  });

  testWidgets('choosing places: remove one, count another at end of day',
      (tester) async {
    final app = await _start(
      tester,
      stays: [
        _stay(Place.parse('US-FL'), 90, 61),
        ..._canadian,
      ],
    );
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('Substantial Presence figure'), findsOneWidget);

    await tester.tap(find.text('Choose places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show places with recorded days'));
    await tester.pumpAndSettle();
    expect(
      app.settings.tracked!.map((t) => t.place),
      [Place.canada, Place.unitedStates],
    );
    await tester.tap(find.byTooltip('Remove: United States'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End of the day'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('United States'), findsNothing);
    expect(find.text('Substantial Presence figure'), findsNothing);
    expect(find.text('Canada (end of day)'), findsOneWidget);
    expect(
      find.text('Rows marked "end of day" count where you were at midnight.'),
      findsOneWidget,
    );
  });

  testWidgets('a home base adds an "assumed at home" row', (tester) async {
    final app = await _start(
      tester,
      stays: [_stay(Place.parse('US-FL'), 30, 10)],
    );
    expect(find.text('Not recorded'), findsOneWidget);
    expect(find.text('Assumed at home'), findsNothing);

    await tester.tap(find.text('Choose places'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Count unrecorded days at home'));
    await tester.pumpAndSettle();
    expect(find.text('Add your home place first.'), findsOneWidget);
    expect(app.settings.homeEnabled, isFalse);

    await tester.ensureVisible(find.text('Add home place'));
    await tester.tap(find.text('Add home place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ontario'));
    await tester.pumpAndSettle();
    expect(find.text('Home from'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(app.settings.homeEnabled, isTrue);
    expect(find.textContaining('Ontario, Canada, from'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Assumed at home'), findsOneWidget);
    expect(find.text('Canada'), findsOneWidget);
  });

  group('the upgrade note (MIG-4)', () {
    final v2 = jsonEncode({
      'schemaVersion': 2,
      'trips': [
        {
          'id': 'old',
          'arrivalDate': '2026-01-05',
          'departureDate': '2026-03-31',
          'status': 'actual',
        },
      ],
    });

    testWidgets('shows once to someone upgrading with trips', (tester) async {
      final app = await _start(
        tester,
        prefs: {..._onboarded, 'snowbird.trips.v1': v2},
      );
      expect(find.text('New: days by place'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(app.storage.placesNoteShown, isTrue);

      app
        ..storage = StorageService(await SharedPreferences.getInstance())
        ..trips = TripRepository(app.storage)
        ..settings = PresenceSettings(app.storage);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_wrap(app, const TripListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('New: days by place'), findsNothing);
    });

    testWidgets('never shows to a new user', (tester) async {
      final app = await _start(tester);
      expect(find.text('New: days by place'), findsNothing);
      expect(app.storage.placesNoteShown, isTrue);
    });
  });

  testWidgets('the places screen opens with nothing recorded', (tester) async {
    await _start(tester, home: const PlacesSettingsScreen());
    expect(find.text('Places in the table'), findsOneWidget);
    expect(find.text('Home base'), findsOneWidget);
  });
}
