import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  group('AddressDetails', () {
    group('isEmpty / isNotEmpty', () {
      test('isEmpty when no values provided', () {
        expect(AddressDetails().isEmpty, isTrue);
        expect(AddressDetails().isNotEmpty, isFalse);
      });

      test('isNotEmpty when any field is set', () {
        expect(AddressDetails(apt: '4B').isNotEmpty, isTrue);
        expect(AddressDetails(floor: '3').isNotEmpty, isTrue);
        expect(AddressDetails(deliveryNotes: 'Leave it').isNotEmpty, isTrue);
      });
    });

    test('named constructor sets built-in getters', () {
      final d = AddressDetails(apt: '4B', floor: '3', deliveryNotes: 'ring bell');
      expect(d.apt, '4B');
      expect(d.floor, '3');
      expect(d.deliveryNotes, 'ring bell');
    });

    test('subscript operator reads arbitrary keys', () {
      const d = AddressDetails.fromValues({'gate': '1234', 'apt': '4B'});
      expect(d['gate'], '1234');
      expect(d['apt'], '4B');
      expect(d['missing'], isNull);
    });

    test('JSON round-trip preserves keyed values', () {
      final original = AddressDetails(apt: '4B', floor: '3');
      final restored = AddressDetails.fromJson(original.toJson());

      expect(restored.apt, original.apt);
      expect(restored.floor, original.floor);
      expect(restored.deliveryNotes, isNull);
    });

    test('fromJson tolerates missing keys', () {
      final restored = AddressDetails.fromJson({'apt': '4B'});
      expect(restored.apt, '4B');
      expect(restored.floor, isNull);
    });

    test('equality and hashCode', () {
      final a = AddressDetails(apt: '1', floor: '2');
      final b = AddressDetails(apt: '1', floor: '2');
      final c = AddressDetails(apt: '1', floor: '9');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('copyWith merges over existing values', () {
      final a = AddressDetails(apt: '1', floor: '2');
      final b = a.copyWith(values: {'floor': '9'});

      expect(b.apt, '1');
      expect(b.floor, '9');
    });

    test('fromValues stores custom field keys', () {
      const d = AddressDetails.fromValues({'building': 'Tower A'});
      expect(d['building'], 'Tower A');
      expect(d.isEmpty, isFalse);
    });
  });
}
