// EN: Widget smoke tests that build the real screens end-to-end (with the same
//     Provider + localisation wiring as main.dart) so a build-time widget error
//     — a bad SegmentedButton, a null deref in a tile, a dialog that never shows —
//     is caught here rather than on a physical device. Covers the first-launch
//     onboarding flow (FR-14 disclaimer + FR-11 one-time backup reminder) and
//     adding a trip through the form (FR-1/FR-2).
//
// FR: Tests de fumée d'interface qui construisent les vrais écrans de bout en bout
//     (avec le même câblage Provider + localisation que main.dart) pour qu'une
//     erreur de widget au build — un SegmentedButton fautif, un déréférencement
//     null dans une tuile, un dialogue qui ne s'affiche pas — soit attrapée ici
//     plutôt que sur un appareil physique. Couvre le parcours d'accueil au premier
//     lancement (avertissement FR-14 + rappel de sauvegarde unique FR-11) et
//     l'ajout d'un séjour via le formulaire (FR-1/FR-2).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/screens/trip_list_screen.dart';
import 'package:snowbird_in_usa_tracker/services/storage_service.dart';
import 'package:snowbird_in_usa_tracker/state/trip_repository.dart';

Widget _wrap(StorageService storage, TripRepository trips) {
  return MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider<TripRepository>.value(value: trips),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: TripListScreen(),
    ),
  );
}

// EN: A tall surface so the whole lazily-built form exists at once.
// FR: Une grande surface pour que tout le formulaire, construit à la demande,
//     existe d'un coup.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<(StorageService, TripRepository)> _freshRepo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  return (storage, TripRepository(storage));
}

void main() {
  testWidgets(
      'first launch shows disclaimer then backup reminder, then empty state',
      (tester) async {
    final (storage, trips) = await _freshRepo();
    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();

    // EN: Disclaimer first (FR-14).
    // FR: Avertissement d'abord (FR-14).
    expect(find.text('A personal tracking tool — not advice'), findsOneWidget);
    await tester.tap(find.text('I understand'));
    await tester.pumpAndSettle();

    // EN: Then the single backup reminder (FR-11).
    // FR: Puis l'unique rappel de sauvegarde (FR-11).
    expect(find.text('Keeping your data safe'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No trips recorded yet'), findsOneWidget);
    expect(storage.disclaimerAcknowledged, isTrue);
    expect(storage.backupReminderShown, isTrue);
  });

  testWidgets('onboarding never shows again once acknowledged', (tester) async {
    SharedPreferences.setMockInitialValues({
      'snowbird.flags.disclaimerAck.v1': true,
      'snowbird.flags.backupReminderShown.v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final trips = TripRepository(storage);

    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();

    expect(find.text('A personal tracking tool — not advice'), findsNothing);
    expect(find.text('Keeping your data safe'), findsNothing);
  });

  testWidgets('trip form renders its fields and enforces the mandatory dates',
      (tester) async {
    _tallView(tester);
    SharedPreferences.setMockInitialValues({
      'snowbird.flags.disclaimerAck.v1': true,
      'snowbird.flags.backupReminderShown.v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final trips = TripRepository(storage);

    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();

    // EN: Open the add-trip form and confirm every section builds. (Driving the
    //     OS date picker is intentionally left to physical testing — it is fragile
    //     in widget tests; here we verify the form renders and validates.)
    // FR: Ouvrir le formulaire d'ajout et confirmer que chaque section se
    //     construit. (Piloter le sélecteur de date de l'OS est laissé au test
    //     physique — il est fragile en test de widget ; ici on vérifie le rendu et
    //     la validation du formulaire.)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add trip'), findsOneWidget);
    expect(find.text('Trip type'), findsOneWidget);
    expect(find.text('Arrival date'), findsOneWidget);
    expect(find.text('Departure date'), findsOneWidget);
    expect(find.text('Trip name (optional)'), findsOneWidget);
    expect(find.text('Entry crossing (optional)'), findsOneWidget);
    expect(find.text('Exit crossing (optional)'), findsOneWidget);

    // EN: The optional detail sections expand to reveal their fields.
    // FR: Les sections de détails facultatifs se déploient pour révéler leurs champs.
    await tester.tap(find.text('Entry crossing (optional)'));
    await tester.pumpAndSettle();
    expect(find.text('Location (optional)'), findsOneWidget);
    expect(find.text('Means of travel (optional)'), findsOneWidget);
    expect(find.text('Carrier (optional)'), findsOneWidget);

    // EN: Saving with no dates chosen must NOT create a trip — it surfaces the
    //     mandatory-date validation message instead (FR-1/FR-5). Save sits at the
    //     bottom of a lazy ListView, so scroll it into view first.
    // FR: Enregistrer sans dates ne doit PAS créer de séjour — cela affiche plutôt
    //     le message de validation des dates obligatoires (FR-1/FR-5). Enregistrer
    //     est au bas d'un ListView paresseux ; le faire défiler dans la vue d'abord.
    final saveButton = find.widgetWithText(FilledButton, 'Save');
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(saveButton, 400, scrollable: scrollable);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    // EN: One frame to fire the handler, a second to animate the SnackBar in.
    // FR: Une image pour déclencher le gestionnaire, une seconde pour animer le
    //     SnackBar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Select an arrival date.'), findsOneWidget);
    expect(trips.tripCount, 0);
  });

  testWidgets('export sheet offers all four formats when trips exist',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'snowbird.flags.disclaimerAck.v1': true,
      'snowbird.flags.backupReminderShown.v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final trips = TripRepository(storage);
    await trips.addTrip(
      Trip.create(
        arrivalDate: DateTime(2025, 1, 5),
        departureDate: DateTime(2025, 3, 1),
        status: TripStatus.actual,
      ),
    );

    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();

    // EN: Open the export sheet (the actual PDF/PNG/print/share handoff crosses a
    //     platform channel and is verified on a device — here we prove the sheet
    //     wiring and that every format is offered).
    // FR: Ouvrir la feuille d'export (la remise PDF/PNG/impression/partage traverse
    //     un canal de plateforme et est vérifiée sur un appareil — ici on prouve le
    //     câblage de la feuille et que chaque format est proposé).
    await tester.tap(find.byIcon(Icons.ios_share_rounded));
    await tester.pumpAndSettle();

    expect(find.text('PDF document'), findsOneWidget);
    expect(find.text('Image (PNG)'), findsOneWidget);
    expect(find.text('Spreadsheet (CSV)'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
  });

  const onboarded = {
    'snowbird.flags.disclaimerAck.v1': true,
    'snowbird.flags.backupReminderShown.v1': true,
  };

  testWidgets('unreadable data is announced, not silently hidden',
      (tester) async {
    SharedPreferences.setMockInitialValues(
      {...onboarded, 'snowbird.trips.v1': '[{"id":5}]'},
    );
    final storage = StorageService(await SharedPreferences.getInstance());
    await tester.pumpWidget(_wrap(storage, TripRepository(storage)));
    await tester.pumpAndSettle();
    expect(find.text('Some saved data could not be read'), findsOneWidget);
  });

  testWidgets('an open trip shows as current and can be closed or blocked',
      (tester) async {
    _tallView(tester);
    SharedPreferences.setMockInitialValues(onboarded);
    final storage = StorageService(await SharedPreferences.getInstance());
    final trips = TripRepository(storage);
    final today = DateTime.now();
    await trips.addTrip(
      Trip.create(
        arrivalDate: DateTime(today.year, today.month, today.day - 2),
        departureDate: null,
        status: TripStatus.actual,
      ),
    );
    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();
    expect(find.text('Current'), findsOneWidget);
    expect(find.textContaining('3 days so far'), findsOneWidget);

    // EN: A new open trip starting today conflicts; the editor must stay open.
    // FR: Un nouveau séjour ouvert dès aujourd'hui est en conflit ; l'éditeur doit
    //     rester ouvert.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arrival date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am still in the US'));
    await tester.pumpAndSettle();
    expect(find.text('Departure date'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('overlap another actual trip'), findsOneWidget);
    expect(trips.tripCount, 1);
  });

  testWidgets('a departure can be recorded on an open trip', (tester) async {
    _tallView(tester);
    SharedPreferences.setMockInitialValues(onboarded);
    final storage = StorageService(await SharedPreferences.getInstance());
    final trips = TripRepository(storage);
    final today = DateTime.now();
    await trips.addTrip(
      Trip.create(
        arrivalDate: DateTime(today.year, today.month, today.day),
        departureDate: null,
        status: TripStatus.actual,
      ),
    );
    await tester.pumpWidget(_wrap(storage, trips));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('I am still in the US'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Departure date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(trips.trips.single.daysInUS, 1);
  });
}
