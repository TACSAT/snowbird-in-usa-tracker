// EN: Tests for exports by place (REQUIREMENTS-places.md section 11 and the
//     acceptance list in section 18):
//     - the US-only record matches today's content, proven against frozen
//       copies of the old CSV and text builders over random histories;
//     - a US-only export contains no other place, in any format;
//     - a default export contains no work detail, and one with work does;
//     - all-places and one-country records carry per-place totals that equal
//       the engine's, with assumed and planned days apart;
//     - the day-by-day ledger lets anyone recount the totals.
// FR: Tests des exports par lieu (REQUIREMENTS-places.md, section 11 et la
//     liste d'acceptation de la section 18) :
//     - la fiche des États-Unis seuls reproduit le contenu d'aujourd'hui,
//       prouvé contre des copies figées des anciens générateurs CSV et texte
//       sur des historiques aléatoires ;
//     - un export des États-Unis seuls ne contient aucun autre lieu, dans
//       aucun format ;
//     - un export par défaut ne contient aucun détail de travail, et un export
//       avec travail en contient ;
//     - les fiches de tous les lieux et d'un pays portent des totaux par lieu
//       égaux à ceux du moteur, avec jours présumés et planifiés à part ;
//     - le registre jour par jour permet à chacun de recompter les totaux.

import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snowbird_in_usa_tracker/l10n/app_localizations.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_ledger.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/day_visit.dart';
import 'package:snowbird_in_usa_tracker/models/home_base.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/tracked_place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';
import 'package:snowbird_in_usa_tracker/models/work_plan.dart';
import 'package:snowbird_in_usa_tracker/services/record_text.dart';

import '../support/legacy_presence_record.dart';
import '../support/legacy_record_text.dart';
import '../support/legacy_trip.dart';

final _asOf = DateTime(2026, 11, 26);
final _en = lookupAppLocalizations(const Locale('en'));

// EN: A small RFC 4180 reader: enough to compare fields, quotes included.
// FR: Un petit lecteur RFC 4180 : assez pour comparer les champs, guillemets
//     compris.
List<List<String>> _parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
      i++;
    } else {
      field.write(c);
    }
  }
  row.add(field.toString());
  rows.add(row);
  return rows;
}

List<LegacyTrip> _legacyHistory(Random r) {
  final trips = <LegacyTrip>[];
  var day = DateTime(2024, 1, 1 + r.nextInt(300));
  final count = r.nextInt(12);
  for (var i = 0; i < count && day.isBefore(_asOf); i++) {
    var end = DateTime(day.year, day.month, day.day + r.nextInt(90));
    if (end.isAfter(_asOf)) end = _asOf;
    final open = i == count - 1 && r.nextBool();
    trips.add(
      LegacyTrip.create(
        arrivalDate: day,
        departureDate: open ? null : end,
        status: LegacyTripStatus.actual,
        name: r.nextBool() ? 'Trip, "$i"' : null,
        notes: r.nextInt(4) == 0 ? '=risky\nnote $i' : null,
        arrivalInfo: r.nextBool()
            ? CrossingInfo.fromInput(location: 'Lacolle', timeMinutes: 600)
            : null,
      ),
    );
    if (open) break;
    day = DateTime(end.year, end.month, end.day + r.nextInt(60));
  }
  if (r.nextBool()) {
    trips.add(
      LegacyTrip.create(
        arrivalDate: DateTime(2027, 1, 3),
        departureDate: DateTime(2027, 2, 3),
        status: LegacyTripStatus.planned,
      ),
    );
  }
  return trips..shuffle(r);
}

Trip _stay(
  String code,
  DateTime a,
  DateTime? d, {
  TripStatus status = TripStatus.actual,
  WorkPlan? work,
  String? notes,
}) =>
    Trip.create(
      arrivalDate: a,
      departureDate: d,
      status: status,
      place: Place.parse(code),
      work: work,
      notes: notes,
    );

final _mixed = [
  _stay('US-FL', DateTime(2026, 1, 5), DateTime(2026, 3, 31)),
  _stay(
    'CA-ON',
    DateTime(2026, 3, 31),
    DateTime(2026, 6, 1),
    work: WorkPlan(weekdays: {1, 2, 3, 4, 5}),
    notes: 'Ontario job',
  ),
  _stay('MX-SON', DateTime(2026, 6, 1), DateTime(2026, 6, 20)),
  _stay(
    'CA-QC',
    DateTime(2026, 12, 10),
    DateTime(2026, 12, 20),
    status: TripStatus.planned,
  ),
];
final _visits = [
  DayVisit(
    id: 'v1',
    date: DateTime(2026, 5, 4),
    place: Place.parse('CA-QC'),
    worked: true,
  ),
  DayVisit(id: 'v2', date: DateTime(2026, 7, 4), place: Place.unitedStates),
];
final _home =
    HomeBase([HomePeriod(place: Place.parse('CA-ON'), from: DateTime(2020))]);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('fr');
  });

  group('the US-only record matches today\'s content', () {
    test('CSV: same rows and figures; place columns only at the end', () {
      final r = Random(77);
      for (var n = 0; n < 200; n++) {
        final old = _legacyHistory(r);
        final migrated = [for (final t in old) Trip.fromJson(t.toJson())];
        final before = _parseCsv(
          LegacyPresenceRecord.build(trips: old, asOf: _asOf).toCsv(),
        );
        final after = _parseCsv(
          PresenceRecord.build(trips: migrated, asOf: _asOf).toCsv(),
        );
        // EN: The single documented addition at the very end.
        // FR: L'unique ajout documenté, tout à la fin.
        expect(after.last.first, 'Counted by');
        final body = after.sublist(0, after.length - 1);
        expect(body, hasLength(before.length), reason: 'history $n');
        const added = ['Country code', 'Country', 'Region code', 'Region'];
        for (var i = 0; i < before.length; i++) {
          final isTable = i >= 4 && i <= 4 + old.length;
          if (isTable) {
            final row = body[i];
            expect(row.sublist(0, row.length - 4), before[i], reason: '$n:$i');
            expect(
              row.sublist(row.length - 4),
              i == 4 ? added : ['US', 'United States', '', ''],
            );
          } else {
            expect(body[i], before[i], reason: 'history $n, row $i');
          }
        }
      }
    });

    test('text: every old line kept in order; only place and counting added',
        () {
      final r = Random(78);
      for (final locale in ['en', 'fr']) {
        final strings = lookupAppLocalizations(Locale(locale));
        for (var n = 0; n < 60; n++) {
          final old = _legacyHistory(r);
          final migrated = [for (final t in old) Trip.fromJson(t.toJson())];
          final before = buildLegacyRecordText(
            LegacyPresenceRecord.build(trips: old, asOf: _asOf),
            strings: strings,
            localeName: locale,
          ).split('\r\n');
          final after = buildRecordText(
            PresenceRecord.build(trips: migrated, asOf: _asOf),
            strings: strings,
            localeName: locale,
          ).split('\r\n');
          final allowed = {
            strings.recordLine(strings.fieldPlace, 'United States'),
            strings.recordLine(
              strings.fieldPlace,
              strings.placeName('US'),
            ),
            strings.recordCountedBy(strings.conventionAnyPart),
          };
          var j = 0;
          for (final line in after) {
            if (j < before.length && line == before[j]) {
              j++;
            } else {
              expect(allowed, contains(line), reason: '$locale $n: "$line"');
            }
          }
          expect(j, before.length, reason: 'every old line, in order');
        }
      }
    });
  });

  test('a US-only export contains no other place, in any format', () {
    final record = PresenceRecord.build(
      trips: _mixed,
      visits: _visits,
      home: _home,
      asOf: _asOf,
    );
    expect(record.isUnitedStates, isTrue);
    expect(record.trips.every((t) => t.place.countryCode == 'US'), isTrue);
    final text = buildRecordText(record, strings: _en, localeName: 'en');
    for (final output in [record.toCsv(), record.toLedgerCsv(), text]) {
      for (final other in [
        'Canada',
        'Ontario',
        'Quebec',
        'Mexico',
        'Sonora',
        'CA-',
        'MX',
        'Ontario job',
      ]) {
        expect(output, isNot(contains(other)), reason: other);
      }
    }
    expect(record.toCsv(), contains('Day visit'));
  });

  group('work in exports (WRK-8)', () {
    for (final scope in [null, Place.canada, Place.unitedStates]) {
      test('none by default; present only when added (${scope?.code})', () {
        PresenceRecord build(bool work) => PresenceRecord.build(
              trips: _mixed,
              visits: _visits,
              asOf: _asOf,
              scope: scope,
              includeWork: work,
            );
        final off = build(false);
        final offText = buildRecordText(off, strings: _en, localeName: 'en');
        for (final output in [off.toCsv(), off.toLedgerCsv(), offText]) {
          expect(output.toLowerCase(), isNot(contains('worked')));
        }
        if (scope == Place.unitedStates) return;
        final on = build(true);
        expect(on.toCsv(), contains('Days worked'));
        expect(on.toLedgerCsv(), contains('Worked in'));
        expect(
          buildRecordText(on, strings: _en, localeName: 'en'),
          contains('Days worked: 45 days'),
        );
      });
    }
  });

  group('all places and one country', () {
    test('per-place totals equal the engine; assumed and planned apart', () {
      final record = PresenceRecord.build(
        trips: _mixed,
        visits: _visits,
        home: _home,
        asOf: _asOf,
        scope: null,
        tracked: const [
          TrackedPlace(Place.canada),
          TrackedPlace(
            Place.unitedStates,
            convention: CountingConvention.endOfDay,
          ),
          TrackedPlace(Place.mexico),
        ],
      );
      expect(record.trips, hasLength(4));
      expect(record.showsSpt, isTrue);
      final ledger = PresenceLedger.build(
        stays: _mixed,
        visits: _visits,
        home: _home,
        from: DateTime(2025),
        to: _asOf,
        today: _asOf,
      );
      final canada = record.places[0];
      expect(
        canada.thisCalendarYear,
        ledger.daysIn(Place.canada, start: DateTime(2026)),
      );
      expect(
        canada.assumedThisYear,
        ledger.assumedIn(Place.canada, start: DateTime(2026)),
      );
      expect(canada.assumedThisYear, greaterThan(0));
      expect(canada.plannedThisYear, 11);
      final us = record.places[1];
      expect(us.convention, CountingConvention.endOfDay);
      expect(us.thisCalendarYear, 85, reason: 'end of day: 5 Jan to 30 Mar');
      final csv = record.toCsv();
      expect(csv, contains('Presence Record'));
      expect(csv, isNot(contains('US Presence Record')));
      expect(csv, contains('United States — counted by,end of day'));
      expect(
        csv,
        contains('"Canada — planned, rest of this calendar year",11'),
      );
      expect(csv, contains('assumed at home'));
      expect(csv, contains('Substantial Presence figure'));
      final text = buildRecordText(record, strings: _en, localeName: 'en');
      expect(text, contains('Place: Sonora, Mexico'));
      expect(text, contains('Counted by: End of the day'));
      expect(text, contains('Assumed at home, not recorded: '));
    });

    test('Canada only: its stays and regions, no SPT, nothing else', () {
      final record = PresenceRecord.build(
        trips: _mixed,
        visits: _visits,
        asOf: _asOf,
        scope: Place.canada,
      );
      expect(record.trips.map((t) => t.place.code), ['CA-ON', 'CA-QC']);
      expect(record.visits.single.place, Place.parse('CA-QC'));
      expect(record.showsSpt, isFalse);
      expect(
        record.places.map((p) => p.place.code),
        ['CA', 'CA-ON', 'CA-QC'],
      );
      final csv = record.toCsv();
      expect(csv, contains('Presence Record: Canada'));
      for (final other in ['Florida', 'Mexico', 'Substantial']) {
        expect(csv, isNot(contains(other)));
      }
      expect(
        buildRecordText(record, strings: _en, localeName: 'en'),
        startsWith('Presence Record: Canada'),
      );
    });
  });

  test('the ledger lets anyone recount: one row per date, sums match', () {
    final record = PresenceRecord.build(
      trips: _mixed,
      visits: _visits,
      home: _home,
      asOf: _asOf,
      scope: null,
    );
    final rows = _parseCsv(record.toLedgerCsv());
    final header = rows[4];
    expect(header.first, 'Date');
    final days = rows.sublist(5);
    expect(days.first.first, '2024-01-01');
    expect(days.last.first, '2026-11-26');
    expect(days, hasLength(_asOf.difference(DateTime(2024)).inDays + 1));
    int count(bool Function(List<String>) test) =>
        days.where((d) => d.first.startsWith('2026') && test(d)).length;
    expect(
      count((d) => d[1].split('; ').any((c) => c.startsWith('US'))),
      record.totals.thisCalendarYear,
    );
    expect(
      count((d) => d[1].split('; ').any((c) => c.startsWith('CA'))),
      record.places.firstWhere((p) => p.place == Place.canada).thisCalendarYear,
    );
    expect(
      days.firstWhere((d) => d.first == '2026-03-31')[1],
      'US-FL; CA-ON',
      reason: 'a crossing day, both places by any part',
    );
    expect(days.firstWhere((d) => d.first == '2026-03-31')[3], 'CA-ON');
    expect(
      days.firstWhere((d) => d.first == '2026-08-01')[5],
      'Ontario, Canada',
      reason: 'assumed at home, said in words',
    );
  });
}
