// EN: Headless verification of the PDF builder (FR-8). buildPdf is pure Dart
//     (the pdf package), so it runs without a device — which lets us prove the
//     risky part: that the Latin-1 normalisation in RecordExporter._pdf survives
//     real French + typographic input (accents, guillemets, em dash, the ⅓/⅙
//     fractions, the ð in the author credit) and emits a well-formed PDF instead of
//     throwing on an unsupported glyph. The PNG raster, the print dialog, and the
//     OS share sheet all need platform channels, so those are verified on a device
//     during physical testing, not here.
//
// FR: Vérification hors-appareil du constructeur de PDF (FR-8). buildPdf est du Dart
//     pur (le paquet pdf), donc il s'exécute sans appareil — ce qui permet de
//     prouver la partie risquée : que la normalisation Latin-1 de
//     RecordExporter._pdf survit à une vraie entrée française + typographique
//     (accents, guillemets, tiret cadratin, fractions ⅓/⅙, le ð du crédit d'auteur)
//     et produit un PDF bien formé au lieu de lever une exception sur un glyphe non
//     pris en charge. Le rendu PNG, la boîte d'impression et la feuille de partage
//     de l'OS nécessitent des canaux de plateforme, donc ils sont vérifiés sur un
//     appareil lors du test physique, pas ici.

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/record_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // EN: In a running app, flutter_localizations initialises intl's date symbols
  //     for the active locale; a bare test must do it itself, or DateFormat throws.
  // FR: Dans une appli en cours, flutter_localizations initialise les symboles de
  //     date d'intl pour la locale active ; un test nu doit le faire lui-même, sinon
  //     DateFormat lève une exception.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  // EN: A trip whose text deliberately contains characters outside Latin-1 or that
  //     need normalising: accents, guillemets, an em dash.
  // FR: Un séjour dont le texte contient volontairement des caractères hors Latin-1
  //     ou à normaliser : accents, guillemets, un tiret cadratin.
  final trips = [
    Trip(
      id: 'a',
      arrivalDate: DateTime(2025, 1, 3),
      departureDate: DateTime(2025, 3, 10),
      status: TripStatus.actual,
      name: 'Hiver à Hallandale — golf & soleil',
      notes: 'Passage « terrestre » à Lacolle',
    ),
  ];

  bool looksLikePdf(List<int> bytes) =>
      bytes.length > 1000 && String.fromCharCodes(bytes.take(5)) == '%PDF-';

  test('buildPdf emits a valid PDF for the French locale without choking',
      () async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    final record =
        PresenceRecord.build(trips: trips, asOf: DateTime(2025, 6, 1));
    final bytes = await RecordExporter.buildPdf(
      record,
      strings: fr,
      localeName: 'fr',
    );
    expect(looksLikePdf(bytes), isTrue);
  });

  test('buildPdf emits a valid PDF for the English locale', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final record =
        PresenceRecord.build(trips: trips, asOf: DateTime(2025, 6, 1));
    final bytes = await RecordExporter.buildPdf(
      record,
      strings: en,
      localeName: 'en',
    );
    expect(looksLikePdf(bytes), isTrue);
  });
}
