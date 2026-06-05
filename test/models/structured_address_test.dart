import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('StructuredAddress', () {
    group('JSON round-trip', () {
      test('toJson then fromJson preserves all fields', () {
        const original = StructuredAddress(
          displayName: '123 Main St, Springfield',
          latLng: LatLng(40.1, -75.2),
          street: 'Main St',
          houseNumber: '123',
          city: 'Springfield',
          state: 'IL',
          postalCode: '62704',
          country: 'United States',
          countryCode: 'us',
        );

        final restored = StructuredAddress.fromJson(original.toJson());

        expect(restored.displayName, original.displayName);
        expect(restored.latLng, original.latLng);
        expect(restored.street, original.street);
        expect(restored.houseNumber, original.houseNumber);
        expect(restored.city, original.city);
        expect(restored.state, original.state);
        expect(restored.postalCode, original.postalCode);
        expect(restored.country, original.country);
        expect(restored.countryCode, original.countryCode);
      });

      test('fromJson coerces integer lat/lng to double', () {
        final restored = StructuredAddress.fromJson({
          'displayName': 'Equator/Meridian',
          'latitude': 0, // int, not double
          'longitude': 0,
        });

        expect(restored.latLng.latitude, isA<double>());
        expect(restored.latLng, const LatLng(0, 0));
        expect(restored.street, isNull);
      });
    });

    group('primaryLine', () {
      test('combines house number and street when both present', () {
        const a = StructuredAddress(
          displayName: 'ignored',
          latLng: LatLng(0, 0),
          houseNumber: '123',
          street: 'Main St',
        );
        expect(a.primaryLine, '123 Main St');
      });

      test('uses street alone when no house number', () {
        const a = StructuredAddress(
          displayName: 'ignored',
          latLng: LatLng(0, 0),
          street: 'Main St',
        );
        expect(a.primaryLine, 'Main St');
      });

      test('falls back to first segment of displayName', () {
        const a = StructuredAddress(
          displayName: 'Eiffel Tower, Paris, France',
          latLng: LatLng(0, 0),
        );
        expect(a.primaryLine, 'Eiffel Tower');
      });
    });

    group('secondaryLine', () {
      test('joins city, state, postal with commas', () {
        const a = StructuredAddress(
          displayName: 'x',
          latLng: LatLng(0, 0),
          city: 'Springfield',
          state: 'IL',
          postalCode: '62704',
        );
        expect(a.secondaryLine, 'Springfield, IL, 62704');
      });

      test('omits missing parts', () {
        const a = StructuredAddress(
          displayName: 'x',
          latLng: LatLng(0, 0),
          city: 'Springfield',
        );
        expect(a.secondaryLine, 'Springfield');
      });

      test('is empty when no locality fields present', () {
        const a = StructuredAddress(displayName: 'x', latLng: LatLng(0, 0));
        expect(a.secondaryLine, '');
      });
    });

    group('equality', () {
      test('equal when displayName and latLng match (ignores other fields)', () {
        const a = StructuredAddress(
          displayName: 'X',
          latLng: LatLng(1, 2),
          city: 'A',
        );
        const b = StructuredAddress(
          displayName: 'X',
          latLng: LatLng(1, 2),
          city: 'B',
        );
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when latLng differs', () {
        const a = StructuredAddress(displayName: 'X', latLng: LatLng(1, 2));
        const b = StructuredAddress(displayName: 'X', latLng: LatLng(3, 4));
        expect(a, isNot(equals(b)));
      });
    });

    test('copyWith replaces only the given fields', () {
      const a = StructuredAddress(
        displayName: 'X',
        latLng: LatLng(1, 2),
        city: 'Old',
        state: 'ST',
      );
      final b = a.copyWith(city: 'New');

      expect(b.city, 'New');
      expect(b.state, 'ST');
      expect(b.displayName, 'X');
      expect(b.latLng, const LatLng(1, 2));
    });
  });
}
