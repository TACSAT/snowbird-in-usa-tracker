// EN: Widget tests for the export screen (section 11): the scope starts on
//     "all places" when there is more than one country, the preview follows
//     the scope (EXP-6), and the work opt-in is off every time the screen
//     opens (WRK-8).
// FR: Tests d'interface de l'écran d'export (section 11) : la portée commence
//     sur « tous les lieux » quand il y a plus d'un pays, l'aperçu suit la
//     portée (EXP-6), et l'option travail est désactivée à chaque ouverture de
//     l'écran (WRK-8).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/export_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

Future<void> _start(WidgetTester tester, {required bool work}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'snowbird.settings.workEnabled.v1': work,
  });
  final storage = StorageService(await SharedPreferences.getInstance());
  final trips = TripRepository(storage);
  for (final (code, a, d, notes) in [
    ('US-FL', DateTime(2026, 1, 5), DateTime(2026, 3, 31), null),
    ('CA-ON', DateTime(2026, 3, 31), DateTime(2026, 6, 1), 'Job'),
  ]) {
    await trips.addTrip(
      Trip.create(
        arrivalDate: a,
        departureDate: d,
        status: TripStatus.actual,
        place: Place.parse(code),
        notes: notes,
      ),
    );
  }
  final app = MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider<TripRepository>.value(value: trips),
      ChangeNotifierProvider.value(value: PresenceSettings(storage)),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ExportScreen(),
    ),
  );
  // EN: A fresh screen each time, as opening it from the list would be.
  // FR: Un écran neuf à chaque fois, comme son ouverture depuis la liste.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the preview follows the scope', (tester) async {
    await _start(tester, work: false);
    expect(find.text('Places: Canada, United States'), findsOneWidget);
    expect(find.text('2 stays'), findsOneWidget);
    expect(find.text('Notes from 1 stay'), findsOneWidget);
    expect(find.text('Add days worked to this export'), findsNothing);

    await tester.tap(find.text('United States only'));
    await tester.pumpAndSettle();
    expect(find.text('Places: United States'), findsOneWidget);
    expect(find.text('1 stay'), findsOneWidget);
    expect(
      find.text('No notes'),
      findsOneWidget,
      reason: 'the note is Canadian',
    );

    await tester.tap(find.text('Canada only'));
    await tester.pumpAndSettle();
    expect(find.text('Places: Canada'), findsOneWidget);
  });

  testWidgets('days worked are off each time, and the preview says so',
      (tester) async {
    await _start(tester, work: true);
    expect(find.text('Days worked: not included'), findsOneWidget);
    await tester.tap(find.text('Add days worked to this export'));
    await tester.pumpAndSettle();
    expect(find.text('Days worked: included'), findsOneWidget);

    await _start(tester, work: true);
    expect(
      find.text('Days worked: not included'),
      findsOneWidget,
      reason: 'never remembered',
    );
  });
}
