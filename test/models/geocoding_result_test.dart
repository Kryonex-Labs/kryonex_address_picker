import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

import '../_support/fixtures.dart';

void main() {
  group('GeocodingResult.fromPhotonFeature', () {
    test('reads GeoJSON [lon, lat] coordinates in the correct order', () {
      final result = GeocodingResult.fromPhotonFeature(photonFeatureFull);

      // coordinates: [77.5946, 12.9716] => lat 12.9716, lon 77.5946
      expect(result.lat, closeTo(12.9716, 1e-9));
      expect(result.lon, closeTo(77.5946, 1e-9));
      expect(result.latLng.latitude, closeTo(12.9716, 1e-9));
      expect(result.latLng.longitude, closeTo(77.5946, 1e-9));
    });

    test('builds displayName from name/street/city/state/country', () {
      final result = GeocodingResult.fromPhotonFeature(photonFeatureFull);
      expect(
        result.displayName,
        'MG Road, Mahatma Gandhi Road, Bengaluru, Karnataka, India',
      );
    });

    test('uses "Unknown location" when no name parts present', () {
      final result = GeocodingResult.fromPhotonFeature(const {
        'geometry': {
          'type': 'Point',
          'coordinates': [0, 0],
        },
        'properties': <String, dynamic>{},
      });
      expect(result.displayName, 'Unknown location');
    });

    test('parses osm_id into placeId, defaulting to "0" when absent', () {
      expect(
        GeocodingResult.fromPhotonFeature(photonFeatureFull).placeId,
        '123456',
      );
      expect(
        GeocodingResult.fromPhotonFeature(photonFeatureMinimal).placeId,
        '0',
      );
    });

    test('importance is always null (Photon does not expose it)', () {
      expect(
        GeocodingResult.fromPhotonFeature(photonFeatureFull).importance,
        isNull,
      );
    });
  });

  group('GeocodingResult.toStructuredAddress', () {
    test('normalizes Photon keys and lowercases country code', () {
      final address = GeocodingResult.fromPhotonFeature(photonFeatureFull)
          .toStructuredAddress();

      expect(address.houseNumber, '12'); // housenumber -> house_number
      expect(address.street, 'Mahatma Gandhi Road'); // street -> road
      expect(address.city, 'Bengaluru');
      expect(address.state, 'Karnataka');
      expect(address.postalCode, '560001');
      expect(address.country, 'India');
      expect(address.countryCode, 'in'); // "IN" lowercased
    });

    test('falls back to district as town/city when city missing', () {
      final result = GeocodingResult.fromPhotonFeature(const {
        'geometry': {
          'type': 'Point',
          'coordinates': [10, 20],
        },
        'properties': {
          'name': 'Place',
          'district': 'Old Town',
        },
      });

      // district is mapped to the 'town' key, which city resolution reads.
      expect(result.toStructuredAddress().city, 'Old Town');
    });

    test('leaves fields null when absent from the feature', () {
      final address = GeocodingResult.fromPhotonFeature(photonFeatureMinimal)
          .toStructuredAddress();

      expect(address.houseNumber, isNull);
      expect(address.street, isNull);
      expect(address.city, isNull);
      expect(address.postalCode, isNull);
      expect(address.countryCode, isNull);
      expect(address.displayName, 'Somewhere');
    });
  });

  // ── Google Geocoding API ────────────────────────────────────────────────

  group('GeocodingResult.fromGoogleResult', () {
    test('reads lat/lng from geometry.location', () {
      final result = GeocodingResult.fromGoogleResult(googleResultFull);

      expect(result.lat, closeTo(12.9716, 1e-9));
      expect(result.lon, closeTo(77.5946, 1e-9));
      expect(result.latLng.latitude, closeTo(12.9716, 1e-9));
      expect(result.latLng.longitude, closeTo(77.5946, 1e-9));
    });

    test('reads formatted_address as displayName', () {
      final result = GeocodingResult.fromGoogleResult(googleResultFull);
      expect(
        result.displayName,
        '12, Mahatma Gandhi Road, Bengaluru, Karnataka 560001, India',
      );
    });

    test('uses "Unknown location" when formatted_address is null', () {
      final result = GeocodingResult.fromGoogleResult(const {
        'geometry': {
          'location': {'lat': 0, 'lng': 0},
        },
        'address_components': <dynamic>[],
      });
      expect(result.displayName, 'Unknown location');
    });

    test('reads place_id as placeId', () {
      expect(
        GeocodingResult.fromGoogleResult(googleResultFull).placeId,
        'ChIJkbeSa_BfYzARphNChaFPjNc',
      );
    });

    test('defaults placeId to empty string when absent', () {
      final result = GeocodingResult.fromGoogleResult(const {
        'geometry': {
          'location': {'lat': 0, 'lng': 0},
        },
        'address_components': <dynamic>[],
      });
      expect(result.placeId, '');
    });

    test('maps address_components to Nominatim-compatible keys', () {
      final result = GeocodingResult.fromGoogleResult(googleResultFull);
      final addr = result.addressParts;

      expect(addr['house_number'], '12'); // street_number
      expect(addr['road'], 'Mahatma Gandhi Road'); // route
      expect(addr['city'], 'Bengaluru'); // locality
      expect(addr['state'], 'Karnataka'); // admin_area_level_1
      expect(addr['postcode'], '560001'); // postal_code
      expect(addr['country'], 'India'); // country
      expect(addr['country_code'], 'in'); // lowercased short_name
    });

    test('leaves addressParts empty when no components match', () {
      final result = GeocodingResult.fromGoogleResult(googleResultMinimal);
      expect(result.addressParts, isEmpty);
    });

    test('type and importance are always null for Google results', () {
      final result = GeocodingResult.fromGoogleResult(googleResultFull);
      expect(result.type, isNull);
      expect(result.importance, isNull);
    });
  });

  group('GeocodingResult.fromGoogleResult → toStructuredAddress', () {
    test('produces a valid StructuredAddress with all fields', () {
      final address = GeocodingResult.fromGoogleResult(googleResultFull)
          .toStructuredAddress();

      expect(address.houseNumber, '12');
      expect(address.street, 'Mahatma Gandhi Road');
      expect(address.city, 'Bengaluru');
      expect(address.state, 'Karnataka');
      expect(address.postalCode, '560001');
      expect(address.country, 'India');
      expect(address.countryCode, 'in');
    });

    test('leaves fields null for minimal Google results', () {
      final address = GeocodingResult.fromGoogleResult(googleResultMinimal)
          .toStructuredAddress();

      expect(address.houseNumber, isNull);
      expect(address.street, isNull);
      expect(address.city, isNull);
      expect(address.postalCode, isNull);
      expect(address.countryCode, isNull);
      expect(address.displayName, 'San Francisco, CA, USA');
    });
  });

  // ── Places API (New) ────────────────────────────────────────────────────

  group('GeocodingResult.fromGooglePlaceDetails', () {
    test('reads location.latitude / location.longitude', () {
      final result = GeocodingResult.fromGooglePlaceDetails(placeDetailsFull);

      expect(result.lat, closeTo(51.5074, 1e-9));
      expect(result.lon, closeTo(-0.1278, 1e-9));
      expect(result.latLng.latitude, closeTo(51.5074, 1e-9));
      expect(result.latLng.longitude, closeTo(-0.1278, 1e-9));
    });

    test('reads id as placeId', () {
      final result = GeocodingResult.fromGooglePlaceDetails(placeDetailsFull);
      expect(result.placeId, 'ChIJdd4hrwug2EcRmSrV3Vo6llI');
    });

    test('defaults placeId to empty string when id is absent', () {
      final result = GeocodingResult.fromGooglePlaceDetails(const {
        'formattedAddress': 'London',
        'location': {'latitude': 51.5074, 'longitude': -0.1278},
        'addressComponents': <dynamic>[],
      });
      expect(result.placeId, isEmpty);
    });

    test('reads formattedAddress as displayName', () {
      final result = GeocodingResult.fromGooglePlaceDetails(placeDetailsFull);
      expect(
        result.displayName,
        '1 Main Street, London, EC1A 1BB, United Kingdom',
      );
    });

    test('falls back to displayName.text when formattedAddress is absent',
        () {
      final result = GeocodingResult.fromGooglePlaceDetails(const {
        'id': 'fallback-id',
        'displayName': {'text': 'Fallback Display'},
        'location': {'latitude': 0.0, 'longitude': 0.0},
        'addressComponents': <dynamic>[],
      });
      expect(result.displayName, 'Fallback Display');
    });

    test(
        'uses "Unknown location" when both formattedAddress and displayName are absent',
        () {
      final result = GeocodingResult.fromGooglePlaceDetails(const {
        'id': 'no-name-id',
        'location': {'latitude': 0.0, 'longitude': 0.0},
        'addressComponents': <dynamic>[],
      });
      expect(result.displayName, 'Unknown location');
    });

    test('maps addressComponents with longText/shortText to Nominatim keys',
        () {
      final result = GeocodingResult.fromGooglePlaceDetails(placeDetailsFull);
      final addr = result.addressParts;

      expect(addr['house_number'], '1');      // street_number → longText
      expect(addr['road'], 'Main Street');    // route → longText
      expect(addr['city'], 'London');         // locality → longText
      expect(addr['state'], 'England');       // admin_area_level_1 → longText
      expect(addr['postcode'], 'EC1A 1BB');   // postal_code → longText
      expect(addr['country'], 'United Kingdom'); // country → longText
      expect(addr['country_code'], 'gb');     // shortText lowercased
    });

    test('leaves addressParts empty when components list is empty', () {
      final result = GeocodingResult.fromGooglePlaceDetails(placeDetailsMinimal);
      expect(result.addressParts, isEmpty);
    });

    test('type and importance are always null', () {
      final result = GeocodingResult.fromGooglePlaceDetails(placeDetailsFull);
      expect(result.type, isNull);
      expect(result.importance, isNull);
    });
  });

  group('GeocodingResult.fromGooglePlaceDetails → toStructuredAddress', () {
    test('produces a valid StructuredAddress with all fields', () {
      final address = GeocodingResult.fromGooglePlaceDetails(placeDetailsFull)
          .toStructuredAddress();

      expect(address.houseNumber, '1');
      expect(address.street, 'Main Street');
      expect(address.city, 'London');
      expect(address.state, 'England');
      expect(address.postalCode, 'EC1A 1BB');
      expect(address.country, 'United Kingdom');
      expect(address.countryCode, 'gb');
    });

    test('leaves fields null for minimal place details', () {
      final address =
          GeocodingResult.fromGooglePlaceDetails(placeDetailsMinimal)
              .toStructuredAddress();

      expect(address.houseNumber, isNull);
      expect(address.street, isNull);
      expect(address.city, isNull);
      expect(address.postalCode, isNull);
      expect(address.countryCode, isNull);
      expect(address.displayName, 'San Francisco, CA, USA');
    });
  });
}
