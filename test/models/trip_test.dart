// EN: Tests for the expanded Trip model (FR-1): the optional name / notes /
//     per-crossing fields, their length caps and time validation (FR-5), and the
//     forward-compatible (additive) serialisation that lets old date-only records
//     load unchanged (FR-12). The day-count maths lives in day_counter_test.dart;
//     this file only exercises the data model.
//
// FR: Tests du modèle Trip élargi (FR-1) : les champs optionnels nom / notes /
//     par-passage, leurs plafonds de longueur et la validation de l'heure (FR-5),
//     et la sérialisation rétrocompatible (additive) qui permet aux anciens
//     enregistrements « date seulement » de se charger inchangés (FR-12). Le calcul
//     des jours vit dans day_counter_test.dart ; ce fichier n'exerce que le modèle.

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/logic/input_limits.dart';
import 'package:snowbird_in_usa_tracker/models/crossing_info.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

void main() {
  group('Trip optional fields', () {
    test('date-only trip stores no optional keys', () {
      final trip = Trip.create(
        arrivalDate: DateTime(2026, 1, 10),
        departureDate: DateTime(2026, 3, 20),
        status: TripStatus.actual,
      );
      final json = trip.toJson();
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('notes'), isFalse);
      expect(json.containsKey('arrivalInfo'), isFalse);
      expect(json.containsKey('departureInfo'), isFalse);
    });

    test('full trip round-trips through JSON unchanged', () {
      final trip = Trip.create(
        arrivalDate: DateTime(2026, 1, 10),
        departureDate: DateTime(2026, 3, 20),
        status: TripStatus.planned,
        name: 'Winter in Hallandale',
        notes: 'Bring the golf clubs.',
        arrivalInfo: CrossingInfo.fromInput(
          timeMinutes: 9 * 60 + 30,
          timeZone: 'EST',
          location: 'Champlain–Lacolle',
          meansOfTravel: 'Car',
          carrier: 'Personal vehicle',
        ),
        departureInfo: CrossingInfo.fromInput(
          timeMinutes: 14 * 60,
          location: 'Toronto Pearson',
          meansOfTravel: 'Air',
          carrier: 'Air Canada AC123',
        ),
      );

      final restored = Trip.fromJson(trip.toJson());

      expect(restored.name, 'Winter in Hallandale');
      expect(restored.notes, 'Bring the golf clubs.');
      expect(restored.arrivalInfo?.timeMinutes, 9 * 60 + 30);
      expect(restored.arrivalInfo?.formattedTime, '09:30');
      expect(restored.arrivalInfo?.timeZone, 'EST');
      expect(restored.arrivalInfo?.location, 'Champlain–Lacolle');
      expect(restored.departureInfo?.carrier, 'Air Canada AC123');
      expect(restored.departureInfo?.timeMinutes, 14 * 60);
    });

    test('an all-blank CrossingInfo collapses to null (no empty object stored)',
        () {
      final trip = Trip.create(
        arrivalDate: DateTime(2026, 1, 10),
        departureDate: DateTime(2026, 1, 12),
        status: TripStatus.actual,
        arrivalInfo: CrossingInfo.fromInput(location: '   '),
      );
      expect(trip.arrivalInfo, isNull);
      expect(trip.toJson().containsKey('arrivalInfo'), isFalse);
    });
  });

  group('Length caps (FR-5)', () {
    test('over-long name and notes are truncated, never rejected', () {
      final longName = 'x' * (InputLimits.maxTripNameLength + 50);
      final longNotes = 'y' * (InputLimits.maxNotesLength + 500);
      final trip = Trip.create(
        arrivalDate: DateTime(2026, 1, 1),
        departureDate: DateTime(2026, 1, 2),
        status: TripStatus.actual,
        name: longName,
        notes: longNotes,
      );
      expect(trip.name!.length, InputLimits.maxTripNameLength);
      expect(trip.notes!.length, InputLimits.maxNotesLength);
    });

    test('over-long crossing text is truncated to its cap', () {
      final info = CrossingInfo.fromInput(
        location: 'L' * (InputLimits.maxLocationLength + 10),
      );
      expect(info!.location!.length, InputLimits.maxLocationLength);
    });
  });

  group('Migration / backward compatibility (FR-12)', () {
    test('legacy date-only JSON (no new keys) loads unchanged', () {
      // EN: Exactly what an older app version wrote — no name/notes/crossing keys.
      // FR: Exactement ce qu'une version antérieure a écrit — sans clés
      //     nom/notes/passage.
      final legacy = <String, dynamic>{
        'id': 'legacy-1',
        'arrivalDate': '2025-11-01',
        'departureDate': '2026-02-15',
        'status': 'actual',
      };
      final trip = Trip.fromJson(legacy);
      expect(trip.id, 'legacy-1');
      expect(trip.name, isNull);
      expect(trip.arrivalInfo, isNull);
      expect(trip.daysInUS, greaterThan(0));
    });

    test('malformed crossing time is rejected so the record can be skipped',
        () {
      final bad = <String, dynamic>{
        'id': 'bad-1',
        'arrivalDate': '2026-01-01',
        'departureDate': '2026-01-05',
        'status': 'actual',
        'arrivalInfo': {'time': '99:99'},
      };
      expect(() => Trip.fromJson(bad), throwsFormatException);
    });
  });

  group('CrossingInfo time parsing', () {
    test('valid "HH:mm" parses to minutes-of-day', () {
      final info = CrossingInfo.fromJson({'time': '23:59'});
      expect(info.timeMinutes, 23 * 60 + 59);
    });

    test('out-of-range hour throws', () {
      expect(
        () => CrossingInfo.fromJson({'time': '24:00'}),
        throwsFormatException,
      );
    });

    test('non-HH:mm shape throws', () {
      expect(
        () => CrossingInfo.fromJson({'time': '930'}),
        throwsFormatException,
      );
    });
  });
}
