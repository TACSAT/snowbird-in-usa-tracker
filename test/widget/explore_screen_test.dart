// EN: The explore screen end to end: ranges, the what-if, and the guarantee that a
//     hypothetical trip is never stored unless the user says so.
// FR: L'écran d'exploration de bout en bout : périodes, hypothèse, et la garantie
//     qu'un séjour hypothétique n'est jamais enregistré sans que l'utilisateur le
//     demande.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowbird_in_usa_tracker/state/presence_settings.dart';
import 'package:snowbird_in_usa_tracker/app.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/settings_controller.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

Future<TripRepository> _open(
  WidgetTester tester, {
  List<Trip> trips = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'snowbird.flags.disclaimerAck.v1': true,
    'snowbird.flags.backupReminderShown.v1': true,
    'snowbird.settings.locale.v1': 'en',
  });
  final storage = StorageService(await SharedPreferences.getInstance());
  final repo = TripRepository(storage);
  for (final t in trips) {
    await repo.addTrip(t);
  }
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider.value(value: SettingsController(storage)),
        ChangeNotifierProvider.value(value: repo),
        ChangeNotifierProvider.value(value: PresenceSettings(storage)),
      ],
      child: const SnowBirdApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Explore days and plans'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _pick(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  Trip actual(int from, int? to) => Trip.create(
        arrivalDate: DateTime(today.year, today.month, today.day - from),
        departureDate: to == null
            ? null
            : DateTime(today.year, today.month, today.day - to),
        status: TripStatus.actual,
      );

  testWidgets('presets and a custom range show actual and planned counts',
      (tester) async {
    await _open(tester, trips: [actual(9, 5)]);
    await tester.tap(find.text('Last 365 days'));
    await tester.pumpAndSettle();
    expect(find.text('Actual days so far: 5 days'), findsOneWidget);
    expect(find.text('Including planned trips: 5 days'), findsOneWidget);

    await tester.tap(find.text('Custom range'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Actual days so far'), findsNothing);
    await _pick(tester, 'From');
    await _pick(tester, 'To');
    expect(find.text('Actual days so far: 0 days'), findsOneWidget);
  });

  testWidgets('a what-if shows both sides, stores nothing until saved',
      (tester) async {
    final repo = await _open(tester, trips: [actual(9, 5)]);
    await _pick(tester, 'Possible arrival');
    expect(find.textContaining('With this trip'), findsNothing);
    await _pick(tester, 'Possible departure');
    expect(find.text('Without this trip: 5 days'), findsWidgets);
    expect(find.text('With this trip: 6 days'), findsWidgets);
    expect(find.textContaining('not advice'), findsWidgets);
    expect(repo.tripCount, 1);

    await tester.tap(find.text('Save as a planned trip'));
    await tester.pumpAndSettle();
    expect(repo.tripCount, 2);
    expect(
      repo.trips.where((t) => t.status == TripStatus.planned).single.daysInUS,
      1,
    );
    expect(find.text('Save as a planned trip'), findsNothing);
  });

  testWidgets('the what-if can be cleared without saving', (tester) async {
    final repo = await _open(tester, trips: [actual(9, 5)]);
    await _pick(tester, 'Possible arrival');
    await _pick(tester, 'Possible departure');
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.textContaining('With this trip'), findsNothing);
    expect(repo.tripCount, 1);
  });

  testWidgets('assumptions are stated only when they apply', (tester) async {
    await _open(tester, trips: [actual(9, 5)]);
    expect(find.textContaining('assume your current trip'), findsNothing);
    expect(find.textContaining('dates have passed'), findsNothing);
  });

  testWidgets('an open trip and a past planned trip are disclosed',
      (tester) async {
    await _open(
      tester,
      trips: [
        actual(3, null),
        Trip.create(
          arrivalDate: DateTime(today.year, today.month, today.day - 20),
          departureDate: DateTime(today.year, today.month, today.day - 15),
          status: TripStatus.planned,
        ),
      ],
    );
    expect(find.textContaining('assume your current trip'), findsOneWidget);
    expect(find.textContaining('dates have passed'), findsOneWidget);
  });

  testWidgets('reachable from the menu with no trips at all', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'snowbird.flags.disclaimerAck.v1': true,
      'snowbird.flags.backupReminderShown.v1': true,
      'snowbird.settings.locale.v1': 'en',
    });
    final storage = StorageService(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider.value(value: SettingsController(storage)),
          ChangeNotifierProvider.value(value: TripRepository(storage)),
          ChangeNotifierProvider.value(value: PresenceSettings(storage)),
        ],
        child: const SnowBirdApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore days and plans'));
    await tester.pumpAndSettle();
    expect(find.text('Possible arrival'), findsOneWidget);
  });
}
