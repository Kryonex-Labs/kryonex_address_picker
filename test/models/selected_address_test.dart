import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

import '../_support/fixtures.dart';

void main() {
  group('SelectedAddress', () {
    test('JSON round-trip with details preserves nested data', () {
      final original = buildSelectedAddress(
        details: AddressDetails(apt: '4B', floor: '3'),
      );
      final restored = SelectedAddress.fromJson(original.toJson());

      expect(restored.address, original.address);
      expect(restored.details?.apt, original.details?.apt);
      expect(restored.details?.floor, original.details?.floor);
    });

    test('JSON round-trip without details keeps details null', () {
      final original = buildSelectedAddress();
      final json = original.toJson();
      expect(json['details'], isNull);

      final restored = SelectedAddress.fromJson(json);
      expect(restored.details, isNull);
      expect(restored.address, original.address);
    });

    test('equality compares address and details', () {
      final a = buildSelectedAddress(details: AddressDetails(apt: '1'));
      final b = buildSelectedAddress(details: AddressDetails(apt: '1'));
      final c = buildSelectedAddress(details: AddressDetails(apt: '2'));

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('copyWith replaces only given fields', () {
      final a = buildSelectedAddress();
      final newDetails = AddressDetails(floor: '9');
      final b = a.copyWith(details: newDetails);

      expect(b.details, newDetails);
      expect(b.address, a.address);
    });
  });
}
