import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

import '../_support/fixtures.dart';

void main() {
  group('AddressAttribute.readAttribute', () {
    final address = buildAddress();

    test('displayName returns the full display string', () {
      expect(
        address.readAttribute(AddressAttribute.displayName),
        address.displayName,
      );
    });

    test('street returns the street name', () {
      expect(address.readAttribute(AddressAttribute.street), 'Mahatma Gandhi Road');
    });

    test('houseNumber returns the building number', () {
      expect(address.readAttribute(AddressAttribute.houseNumber), '12');
    });

    test('city returns the city name', () {
      expect(address.readAttribute(AddressAttribute.city), 'Bengaluru');
    });

    test('state returns the state/province', () {
      expect(address.readAttribute(AddressAttribute.state), 'Karnataka');
    });

    test('postalCode returns the postal code', () {
      expect(address.readAttribute(AddressAttribute.postalCode), '560001');
    });

    test('country returns the full country name', () {
      expect(address.readAttribute(AddressAttribute.country), 'India');
    });

    test('countryCode returns the ISO alpha-2 code', () {
      expect(address.readAttribute(AddressAttribute.countryCode), 'in');
    });

    test('latitude returns stringified latitude', () {
      expect(address.readAttribute(AddressAttribute.latitude), '12.9716');
    });

    test('longitude returns stringified longitude', () {
      expect(address.readAttribute(AddressAttribute.longitude), '77.5946');
    });

    test('primaryLine returns composed house number + street', () {
      expect(
        address.readAttribute(AddressAttribute.primaryLine),
        '12 Mahatma Gandhi Road',
      );
    });

    test('secondaryLine returns composed city, state, postal', () {
      expect(
        address.readAttribute(AddressAttribute.secondaryLine),
        'Bengaluru, Karnataka, 560001',
      );
    });

    test('returns null for nullable fields when absent', () {
      final sparse = buildAddress(
        street: null,
        houseNumber: null,
        city: null,
        state: null,
        postalCode: null,
        country: null,
        countryCode: null,
      );

      expect(sparse.readAttribute(AddressAttribute.street), isNull);
      expect(sparse.readAttribute(AddressAttribute.houseNumber), isNull);
      expect(sparse.readAttribute(AddressAttribute.city), isNull);
      expect(sparse.readAttribute(AddressAttribute.state), isNull);
      expect(sparse.readAttribute(AddressAttribute.postalCode), isNull);
      expect(sparse.readAttribute(AddressAttribute.country), isNull);
      expect(sparse.readAttribute(AddressAttribute.countryCode), isNull);
    });
  });
}
