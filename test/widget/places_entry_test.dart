// EN: Widget tests for entering stays by place (REQUIREMENTS-places.md step 2):
//     the chooser, a first stay on a new install, "I have moved to..." from the
//     main screen (counted in taps: the 15-second target), "Add next stop",
//     splitting a stay, and day visits.
// FR: Tests d'interface de la saisie des séjours par lieu (REQUIREMENTS-places.md,
//     étape 2) : le sélecteur, un premier séjour sur une nouvelle installation,
//     « J'ai changé de lieu... » depuis l'écran principal (compté en touchers :
//     l'objectif des 15 secondes), « Ajouter l'étape suivante », la division d'un
//     séjour et les visites d'un jour.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/place_picker_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/split_stay_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_edit_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

const _onboarded = {
  'snowbird.flags.disclaimerAck.v1': true,
  'snowbird.flags.backupReminderShown.v1': true,
};

Widget _wrap(
  StorageService storage,
  TripRepository trips, {
  Widget home = const TripListScreen(),
  Locale locale = const Locale('en'),
}) =>
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<TripRepository>.value(value: trips),
        ChangeNotifierProvider.value(value: PresenceSettings(storage)),
      ],
      child: MaterialApp(
        locale: locale,
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

Future<(StorageService, TripRepository)> _setUp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(_onboarded);
  final storage = StorageService(await SharedPreferences.getInstance());
  return (storage, TripRepository(storage));
}

DateTime _daysAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - n);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a first stay on a new install asks for its place once',
      (tester) async {
    final (storage, trips) = await _setUp(tester);
    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arrival date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am still here'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Save');
    expect(find.text('Choose a place.'), findsOneWidget);
    expect(trips.tripCount, 0);

    await tester.tap(find.text('Place'));
    await tester.pumpAndSettle();
    expect(find.text('Recent'), findsNothing, reason: 'nothing used yet');
    await tester.tap(find.text('Canada'));
    await tester.pumpAndSettle();
    expect(find.text('Canada, region not recorded'), findsOneWidget);
    await tester.tap(find.text('Ontario'));
    await tester.pumpAndSettle();
    expect(find.text('Ontario, Canada'), findsOneWidget);
    expect(find.text('Choose a place.'), findsNothing);

    await _tapText(tester, 'Save');
    expect(trips.trips.single.place, Place.parse('CA-ON'));
    expect(find.textContaining('Ontario, Canada ·'), findsOneWidget);
    expect(find.text('Now: Ontario, Canada, 1 day'), findsOneWidget);

    // EN: The next new stay starts with that place: chosen once (section 18).
    // FR: Le séjour suivant commence avec ce lieu : choisi une fois
    //     (section 18).
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Ontario, Canada'), findsOneWidget);
  });

  for (final (locale, query, expected) in [
    ('en', 'quebec', 'Quebec, Canada'),
    ('fr', 'quebec', 'Québec, Canada'),
    ('en', 'georgia', 'Georgia, United States'),
    ('fr', 'nuevo leon', 'Nuevo León, Mexique'),
    ('fr', 'miquelon', 'Saint-Pierre-et-Miquelon'),
  ]) {
    testWidgets('search "$query" in $locale finds $expected', (tester) async {
      final (storage, trips) = await _setUp(tester);
      await tester.pumpWidget(
        _wrap(
          storage,
          trips,
          home: const PlacePickerScreen(),
          locale: Locale(locale),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('a search with no match says so', (tester) async {
    final (storage, trips) = await _setUp(tester);
    await tester.pumpWidget(
      _wrap(storage, trips, home: const PlacePickerScreen()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'atlantis');
    await tester.pumpAndSettle();
    expect(find.text('No place matches that name.'), findsOneWidget);
  });

  testWidgets('a move from the main screen takes three taps', (tester) async {
    final (storage, trips) = await _setUp(tester);
    await trips.addTrip(
      Trip.create(
        arrivalDate: _daysAgo(40),
        departureDate: _daysAgo(20),
        status: TripStatus.actual,
        place: Place.parse('CA-YT'),
      ),
    );
    await trips.addTrip(
      Trip.create(
        arrivalDate: _daysAgo(10),
        departureDate: null,
        status: TripStatus.actual,
        place: Place.parse('US-AK'),
      ),
    );
    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();

    var taps = 0;
    await tester.tap(find.text('I have moved…'));
    taps++;
    await tester.pumpAndSettle();
    expect(find.text('Recent'), findsOneWidget);
    expect(
      find.text('Alaska, United States'),
      findsNothing,
      reason: 'the current place is not offered as the next one',
    );
    await tester.tap(find.text('Yukon, Canada'));
    taps++;
    await tester.pumpAndSettle();
    expect(find.text('New place: Yukon, Canada'), findsOneWidget);
    await tester.tap(find.text('Save'));
    taps++;
    await tester.pumpAndSettle();

    expect(taps, 3);
    expect(trips.tripCount, 3);
    final ongoing = trips.trips.where((t) => t.departureDate == null).single;
    expect(ongoing.place, Place.parse('CA-YT'));
    expect(ongoing.arrivalDate, _daysAgo(0));
  });

  testWidgets('"Add next stop" starts on the previous departure',
      (tester) async {
    final (storage, trips) = await _setUp(tester);
    final stay = Trip.create(
      arrivalDate: DateTime(2026, 1, 1),
      departureDate: DateTime(2026, 1, 15),
      status: TripStatus.actual,
      place: Place.parse('CA-ON'),
    );
    await trips.addTrip(stay);
    await tester.pumpWidget(
      _wrap(storage, trips, home: TripEditScreen(existing: stay)),
    );
    await tester.pumpAndSettle();
    await _tapText(tester, 'Add next stop');
    expect(find.text('Add trip'), findsOneWidget);
    expect(find.text('January 15, 2026'), findsOneWidget);
    expect(find.text('I have moved…'), findsNothing);
  });

  testWidgets('a stay can be split into two regions of its country',
      (tester) async {
    final (storage, trips) = await _setUp(tester);
    final stay = Trip.create(
      arrivalDate: DateTime(2026, 6, 1),
      departureDate: DateTime(2026, 9, 30),
      status: TripStatus.actual,
      place: Place.canada,
    );
    await trips.addTrip(stay);
    await tester.pumpWidget(
      _wrap(storage, trips, home: SplitStayScreen(stay: stay)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Both parts stay in Canada'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a date within the stay.'), findsOneWidget);
    expect(trips.tripCount, 1);

    await tester.tap(find.text('Second place from'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place from that date'));
    await tester.pumpAndSettle();
    expect(
      find.text('United States'),
      findsNothing,
      reason: 'only the stay\'s own country is offered',
    );
    await _tapText(tester, 'Yukon');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(trips.tripCount, 2);
    expect(trips.trips.map((t) => t.place), contains(Place.parse('CA-YT')));
  });

  testWidgets('a day visit is added, listed, and counted as a US day',
      (tester) async {
    final (storage, trips) = await _setUp(tester);
    await trips.addTrip(
      Trip.create(
        arrivalDate: _daysAgo(30),
        departureDate: null,
        status: TripStatus.actual,
        place: Place.parse('CA-ON'),
      ),
    );
    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('^United States:')), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day visits'));
    await tester.pumpAndSettle();
    expect(find.text('No day visits recorded.'), findsOneWidget);
    await tester.tap(find.text('Add day visit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a place.'), findsOneWidget);
    await tester.tap(find.text('Place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('United States'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Michigan');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(trips.visits.single.place, Place.parse('US-MI'));
    expect(find.text('Michigan, United States'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'United States: 1 day this calendar year, 1 day in the last 365 days',
      ),
      findsOneWidget,
    );
    handle.dispose();
    expect(trips.tripCount, 1, reason: 'a visit is not a stay');
  });
}
