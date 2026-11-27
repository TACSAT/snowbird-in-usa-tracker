// EN: The plain-text record: the same facts as the PDF, readable from top to bottom by a
//     screen reader, in the user's language, with nothing the user recorded left out.
// FR: La fiche en texte brut : les mêmes faits que le PDF, lisible de haut en bas par un
//     lecteur d'écran, dans la langue de l'utilisateur, sans rien omettre de consigné.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/services/record_exporter.dart';
import 'package:snowbird_in_usa_tracker/services/record_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());

  final record = PresenceRecord.build(
    trips: [
      Trip(
        id: 'b',
        arrivalDate: DateTime(2026, 11, 20),
        departureDate: null,
        status: TripStatus.actual,
      ),
      Trip(
        id: 'a',
        arrivalDate: DateTime(2026, 1, 1),
        departureDate: DateTime(2026, 1, 31),
        status: TripStatus.actual,
        name: 'Chez ma sœur 🏌',
        notes: 'line one\nline two',
        arrivalInfo: const CrossingInfo(
          timeMinutes: 870,
          timeZone: 'EST',
          location: 'Champlain–Lacolle',
          meansOfTravel: 'Car',
          carrier: 'ABC 123',
        ),
        departureInfo: const CrossingInfo(location: 'Peace Bridge'),
      ),
      Trip(
        id: 'c',
        arrivalDate: DateTime(2026, 12, 10),
        departureDate: DateTime(2026, 12, 12),
        status: TripStatus.planned,
      ),
    ],
    asOf: DateTime(2026, 11, 24),
  );

  String text(String locale) => buildRecordText(
        record,
        strings: lookupAppLocalizations(Locale(locale)),
        localeName: locale,
      );

  test('English: complete, ordered, one fact per line', () {
    expect(text('en').split('\r\n'), [
      'US Presence Record',
      'As of November 24, 2026',
      '',
      'This is a personal record, not advice. It gives no immigration, tax, '
          'or legal opinion. Verify your situation with a qualified '
          'professional.',
      '',
      'Days present in the US (actual)',
      'This calendar year: 36 days',
      'Last 365 days: 36 days',
      'Last calendar year: 0 days',
      'Substantial Presence figure: 36',
      'current year + 1/3 prior year + 1/6 second-prior year',
      'Counted by: Any part of the day',
      '',
      'Trip 1 of 3',
      'Type: Actual',
      'Place: United States',
      'Trip name: Chez ma sœur 🏌',
      'Arrival date: January 1, 2026',
      'Departure date: January 31, 2026',
      'Days: 31',
      'Entry: 14:30 EST, Champlain–Lacolle, Car, ABC 123',
      'Exit: Peace Bridge',
      'Notes: line one',
      'line two',
      '',
      'Trip 2 of 3',
      'Type: Current',
      'Place: United States',
      'Arrival date: November 20, 2026',
      'Departure date: ongoing',
      'Days: 5',
      '',
      'Trip 3 of 3',
      'Type: Planned',
      'Place: United States',
      'Arrival date: December 10, 2026',
      'Departure date: December 12, 2026',
      'Days: 3',
      '',
      'Kept with SENALOVIRA · teagarden.net',
    ]);
  });

  test('French: labels and dates are French', () {
    final fr = text('fr');
    for (final part in [
      'Fiche de présence aux États-Unis',
      'Séjour 1 sur 3',
      'Type : Réel',
      "Date d'arrivée : 1 janvier 2026",
      'Date de départ : en cours',
      'Cette année civile : 36 jours',
      'Nom du séjour : Chez ma sœur 🏌',
    ]) {
      expect(fr, contains(part));
    }
    expect(fr, isNot(contains('Trip ')));
    expect(fr, isNot(contains('⅓')));
  });

  test('no verdict words in either language', () {
    for (final t in [text('en'), text('fr')]) {
      for (final banned in ['over the limit', 'exceeded', 'dépass', 'alarm']) {
        expect(t.toLowerCase(), isNot(contains(banned)));
      }
    }
  });

  test('the file is UTF-8 with a mark, so phones show accents correctly',
      () async {
    final temp = await Directory.systemTemp.createTemp('snowbird');
    addTearDown(() => temp.delete(recursive: true));
    final file = await RecordExporter.writeText('Fiche é œ', temp);
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(bytes.skip(3).toList()), 'Fiche é œ');
    expect(file.path, endsWith('us-presence-record.txt'));
  });
}
