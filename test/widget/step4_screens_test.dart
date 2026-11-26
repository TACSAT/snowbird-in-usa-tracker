// EN: Widget tests for Step 4 screens: the stay list filter (FEA-4), the alert
//     editor's place, convention and measure (FEA-1, WRK-10), and the what-if
//     place with its per-place results (FEA-2).
// FR: Tests d'interface des écrans de l'étape 4 : le filtre de la liste des
//     séjours (FEA-4), le lieu, la convention et la mesure de l'éditeur
//     d'alerte (FEA-1, WRK-10), et le lieu de l'hypothèse avec ses résultats
//     par lieu (FEA-2).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/alerts_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/explore_screen.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

class _App {
  late StorageService storage;
  late TripRepository trips;
  late PresenceSettings settings;
}

Future<_App> _start(
  WidgetTester tester, {
  required Widget home,
  bool work = false,
  List<Trip> stays = const [],
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
  await tester.pumpWidget(
    MultiProvider(
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
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

Trip _stay(String code, DateTime a, DateTime d, {String? name}) => Trip.create(
      arrivalDate: a,
      departureDate: d,
      status: TripStatus.actual,
      place: Place.parse(code),
      name: name,
    );

final _stays = [
  _stay('US-FL', DateTime(2025, 1, 5), DateTime(2025, 3, 31), name: 'Florida'),
  _stay('CA-ON', DateTime(2025, 3, 31), DateTime(2025, 12, 1), name: 'Home'),
  _stay('MX-SON', DateTime(2026, 1, 2), DateTime(2026, 2, 1), name: 'Sonora'),
];

void main() {
  testWidgets('the list filters by place and by year, and clears',
      (tester) async {
    await _start(tester, home: const TripListScreen(), stays: _stays);
    expect(find.text('Florida'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter stays'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InputDecorator, 'Place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canada').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Florida'), findsNothing);
    expect(find.text('1 of 3 stays shown'), findsOneWidget);

    await tester.tap(find.text('Clear filter'));
    await tester.pumpAndSettle();
    expect(find.text('Florida'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter stays'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InputDecorator, 'Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
    expect(find.text('Sonora'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('alerts name a place; days worked only when work is on',
      (tester) async {
    await _start(tester, home: const AlertEditScreen(), stays: _stays);
    expect(find.text('Mexico'), findsOneWidget, reason: 'last place used');
    expect(find.text('End of the day'), findsOneWidget);
    expect(find.text('What to count'), findsNothing);
  });

  testWidgets('with work on, an alert can count days worked', (tester) async {
    await _start(
      tester,
      home: const AlertEditScreen(),
      stays: _stays,
      work: true,
    );
    expect(find.text('What to count'), findsOneWidget);
    await tester.tap(find.text('Days worked'));
    await tester.pumpAndSettle();
    expect(
      find.text('End of the day'),
      findsNothing,
      reason: 'a day worked is not a question of midnight',
    );
  });

  testWidgets('the what-if has a place; a Mexican trip shows no SPT',
      (tester) async {
    await _start(tester, home: const ExploreScreen(), stays: _stays);
    expect(find.text('Place of this trip'), findsOneWidget);
    expect(find.text('Sonora, Mexico'), findsOneWidget);
    await tester.tap(find.text('Possible arrival'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Possible departure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Mexico'), findsWidgets);
    expect(find.textContaining('Substantial Presence'), findsNothing);

    await tester.tap(find.text('Sonora, Mexico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('United States'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('United States, region not recorded'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Substantial Presence'), findsOneWidget);
  });
}
