// EN: Tests for the PURE presence-record core (FR-8): the per-window totals, the
//     SPT breakdown, and the CSV serialisation (ordering, escaping, planned-vs-
//     actual). The PDF/image/print rendering is a thin skin over this and is
//     exercised on a device; the numbers and the CSV bytes are proven here.
//
// FR: Tests du cœur PUR de la fiche de présence (FR-8) : les totaux par fenêtre, la
//     décomposition SPT et la sérialisation CSV (ordre, échappement, planifié vs
//     réel). Le rendu PDF/image/impression n'est qu'une fine surface au-dessus et
//     est exercé sur un appareil ; les nombres et les octets CSV sont prouvés ici.

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/presence_record.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

void main() {
  // EN: A fixed scenario spanning a year boundary, with a planned trip whose name
  //     and notes contain CSV-hostile characters.
  // FR: Un scénario fixe à cheval sur une fin d'année, avec un séjour planifié dont
  //     le nom et les notes contiennent des caractères hostiles au CSV.
  List<Trip> scenario() => [
        Trip(
          id: 'a',
          arrivalDate: DateTime(2024, 12, 20),
          departureDate: DateTime(2025, 1, 10),
          status: TripStatus.actual,
        ),
        Trip(
          id: 'b',
          arrivalDate: DateTime(2025, 3, 1),
          departureDate: DateTime(2025, 3, 31),
          status: TripStatus.actual,
        ),
        Trip(
          id: 'c',
          arrivalDate: DateTime(2026, 1, 5),
          departureDate: DateTime(2026, 2, 5),
          status: TripStatus.planned,
          name: 'Golf, sun & fun',
          notes: 'He said "hi"',
        ),
      ];

  final asOf = DateTime(2025, 6, 15);

  group('Totals (actual presence only)', () {
    test('per-window counts exclude planned trips', () {
      final r = PresenceRecord.build(trips: scenario(), asOf: asOf);
      expect(r.totals.thisCalendarYear, 41); // Jan 1-10 (10) + Mar (31)
      expect(r.totals.rollingLast365, 53); // trip A 22 + trip B 31
      expect(r.totals.priorCalendarYear, 12); // Dec 20-31 2024
    });

    test('SPT breakdown is exact and weighted', () {
      final r = PresenceRecord.build(trips: scenario(), asOf: asOf);
      expect(r.totals.spt.currentYearDays, 41);
      expect(r.totals.spt.priorYearDays, 12);
      expect(r.totals.spt.secondPriorYearDays, 0);
      // 6*41 + 2*12 + 0 = 270 sixths = 45 exactly.
      expect(r.totals.spt.totalSixths, 270);
      expect(r.formattedSpt, '45');
    });
  });

  group('CSV serialisation', () {
    test('trips appear chronologically, planned marked, actual marked', () {
      final csv = PresenceRecord.build(trips: scenario(), asOf: asOf).toCsv();
      final iA = csv.indexOf('2024-12-20');
      final iB = csv.indexOf('2025-03-01');
      final iC = csv.indexOf('2026-01-05');
      expect(iA, greaterThanOrEqualTo(0));
      expect(iA, lessThan(iB));
      expect(iB, lessThan(iC));
      expect(csv, contains('Planned'));
      expect(csv, contains('Actual'));
    });

    test('a name containing a comma is quoted', () {
      final csv = PresenceRecord.build(trips: scenario(), asOf: asOf).toCsv();
      expect(csv, contains('"Golf, sun & fun"'));
    });

    test('embedded quotes are doubled', () {
      final csv = PresenceRecord.build(trips: scenario(), asOf: asOf).toCsv();
      expect(csv, contains('"He said ""hi"""'));
    });

    test('carries the not-advice line and the neutral summary numbers', () {
      final csv = PresenceRecord.build(trips: scenario(), asOf: asOf).toCsv();
      expect(csv, contains('not advice'));
      expect(csv, contains('SnowBird — US Presence Record'));
      // Summary values present.
      expect(csv, contains('41'));
      expect(csv, contains('53'));
      expect(csv, contains('45'));
    });

    test('never renders a verdict word', () {
      final csv = PresenceRecord.build(trips: scenario(), asOf: asOf)
          .toCsv()
          .toLowerCase();
      for (final banned in ['over the limit', 'safe', 'exceeded', 'warning']) {
        expect(
          csv.contains(banned),
          isFalse,
          reason: 'must stay neutral: $banned',
        );
      }
    });
  });
}
