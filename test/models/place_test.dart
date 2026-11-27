// EN: Tests for places (REQUIREMENTS-places.md section 4) and for the place a
//     stay carries in storage. Codes, not names, are stored (PLC-6); unknown but
//     well-formed codes survive (PLC-8); old records become the United States
//     (MIG-1).
// FR: Tests des lieux (REQUIREMENTS-places.md, section 4) et du lieu qu'un séjour
//     porte dans le stockage. Ce sont des codes, et non des noms, qui sont
//     enregistrés (PLC-6) ; les codes inconnus mais bien formés survivent
//     (PLC-8) ; les anciens enregistrements deviennent les États-Unis (MIG-1).

import 'package:flutter_test/flutter_test.dart';
import 'package:snowbird_in_usa_tracker/models/place.dart';
import 'package:snowbird_in_usa_tracker/models/trip.dart';

void main() {
  group('Place', () {
    test('a code splits into its country and region', () {
      final on = Place.parse('CA-ON');
      expect(on.countryCode, 'CA');
      expect(on.isCountry, isFalse);
      expect(on.country, Place.canada);
      expect(Place.canada.isCountry, isTrue);
      expect(Place.canada.country, Place.canada);
    });

    test('a country contains its regions; a region contains only itself', () {
      final on = Place.parse('CA-ON');
      expect(Place.canada.contains(on), isTrue);
      expect(Place.canada.contains(Place.canada), isTrue);
      expect(on.contains(Place.canada), isFalse);
      expect(on.contains(Place.parse('CA-QC')), isFalse);
      expect(Place.unitedStates.contains(on), isFalse);
    });

    test('US territories and Saint-Pierre-et-Miquelon stand apart', () {
      expect(Place.unitedStates.contains(Place.parse('PR')), isFalse);
      expect(Place.parse('FR').contains(Place.saintPierreAndMiquelon), isFalse);
    });

    test('malformed codes are refused, not guessed', () {
      for (final bad in ['', 'ca', 'CAN', 'CA-', 'CA-ONTA', 'CA_ON', ' US']) {
        expect(() => Place.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('the catalogue has every region the requirements list', () {
      expect(PlaceCatalog.regions[Place.canada], hasLength(13));
      expect(PlaceCatalog.regions[Place.unitedStates], hasLength(51));
      expect(PlaceCatalog.regions[Place.mexico], hasLength(32));
      expect(PlaceCatalog.regions[Place.saintPierreAndMiquelon], isNull);
    });

    test('every catalogue code is well formed, unique and in its country', () {
      final all = [
        ...PlaceCatalog.countries,
        for (final list in PlaceCatalog.regions.values) ...list,
      ];
      expect(all.toSet(), hasLength(all.length));
      for (final place in all) {
        expect(Place.parse(place.code), place);
        expect(PlaceCatalog.isKnown(place), isTrue, reason: place.code);
      }
      PlaceCatalog.regions.forEach((country, regions) {
        for (final region in regions) {
          expect(region.country, country);
        }
      });
    });

    test('a well-formed code from a newer version is kept, though unknown', () {
      final future = Place.parse('CA-XX');
      expect(PlaceCatalog.isKnown(future), isFalse);
      expect(Place.canada.contains(future), isTrue);
    });
  });

  group('a stay\'s place in storage', () {
    Map<String, dynamic> v2Record() => {
          'id': 'a',
          'arrivalDate': '2026-01-01',
          'departureDate': '2026-01-05',
          'status': 'actual',
        };

    test('a record from before places is a stay in the United States', () {
      final trip = Trip.fromJson(v2Record());
      expect(trip.place, Place.unitedStates);
      expect(trip.placeName, isNull);
    });

    test('the place is always written, and read back unchanged', () {
      final trip = Trip.fromJson({...v2Record(), 'place': 'MX-SON'});
      final json = trip.toJson();
      expect(json['place'], 'MX-SON');
      expect(Trip.fromJson(json).place, Place.parse('MX-SON'));
      expect(
        Trip.fromJson(Trip.fromJson(v2Record()).toJson()).toJson()['place'],
        'US',
      );
    });

    test('a malformed place is damage, never counted somewhere else', () {
      expect(
        () => Trip.fromJson({...v2Record(), 'place': 'Ontario'}),
        throwsFormatException,
      );
      expect(
        () => Trip.fromJson({...v2Record(), 'place': 7}),
        throwsFormatException,
      );
    });

    test('an unknown but well-formed place survives a round trip', () {
      final trip = Trip.fromJson({...v2Record(), 'place': 'CA-XX'});
      expect(trip.toJson()['place'], 'CA-XX');
    });

    test('a name is kept only for Elsewhere, trimmed and capped', () {
      final elsewhere = Trip.fromJson({
        ...v2Record(),
        'place': 'ZZ',
        'placeName': '  Iceland  ',
      });
      expect(elsewhere.placeName, 'Iceland');
      final named = Trip.fromJson({
        ...v2Record(),
        'place': 'CA',
        'placeName': 'Iceland',
      });
      expect(named.placeName, isNull);
      expect(named.toJson().containsKey('placeName'), isFalse);
      final long = Trip.create(
        arrivalDate: DateTime(2026),
        departureDate: DateTime(2026),
        status: TripStatus.actual,
        place: Place.elsewhere,
        placeName: 'x' * 500,
      );
      expect(long.placeName, hasLength(80));
    });

    test('moving a stay off Elsewhere drops its name', () {
      final trip = Trip.create(
        arrivalDate: DateTime(2026),
        departureDate: DateTime(2026),
        status: TripStatus.actual,
        place: Place.elsewhere,
        placeName: 'Iceland',
      );
      expect(trip.copyWith(place: Place.canada).placeName, isNull);
      expect(trip.copyWith(notes: 'n').placeName, 'Iceland');
    });
  });
}
