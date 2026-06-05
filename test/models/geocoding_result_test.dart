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

    test('parses osm_id into placeId, defaulting to 0 when absent', () {
      expect(
        GeocodingResult.fromPhotonFeature(photonFeatureFull).placeId,
        123456,
      );
      expect(
        GeocodingResult.fromPhotonFeature(photonFeatureMinimal).placeId,
        0,
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
}
