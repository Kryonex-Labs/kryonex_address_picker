import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  group('AddressFieldSpec.validate', () {
    test('returns error when required field is empty', () {
      const spec = AddressFieldSpec(key: 'name', label: 'Name', required: true);

      expect(spec.validate(null), 'Name is required');
      expect(spec.validate(''), 'Name is required');
      expect(spec.validate('   '), 'Name is required');
    });

    test('returns null when required field has value', () {
      const spec = AddressFieldSpec(key: 'name', label: 'Name', required: true);

      expect(spec.validate('Alice'), isNull);
    });

    test('returns null when optional field is empty', () {
      const spec = AddressFieldSpec(key: 'note', label: 'Note');

      expect(spec.validate(null), isNull);
      expect(spec.validate(''), isNull);
    });

    test('runs custom validator after required check', () {
      final spec = AddressFieldSpec(
        key: 'code',
        label: 'Code',
        required: true,
        validator: (v) => (v != null && v.length < 3) ? 'Too short' : null,
      );

      // required check fires first
      expect(spec.validate(''), 'Code is required');
      // custom validator fires after required passes
      expect(spec.validate('AB'), 'Too short');
      expect(spec.validate('ABC'), isNull);
    });

    test('runs custom validator when field is optional', () {
      final spec = AddressFieldSpec(
        key: 'zip',
        label: 'ZIP',
        validator: (v) {
          final trimmed = v?.trim() ?? '';
          if (trimmed.isNotEmpty && trimmed.length != 5) return 'Must be 5 digits';
          return null;
        },
      );

      expect(spec.validate(''), isNull); // optional + empty = ok
      expect(spec.validate('123'), 'Must be 5 digits');
      expect(spec.validate('12345'), isNull);
    });
  });

  group('AddressFieldSpec equality', () {
    test('specs with same key are equal', () {
      const a = AddressFieldSpec(key: 'apt', label: 'Apartment');
      const b = AddressFieldSpec(key: 'apt', label: 'Apt / Suite');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('specs with different keys are not equal', () {
      const a = AddressFieldSpec(key: 'apt', label: 'Apartment');
      const b = AddressFieldSpec(key: 'floor', label: 'Floor');

      expect(a, isNot(equals(b)));
    });

    test('identical spec equals itself', () {
      expect(AddressFieldSpec.apt, equals(AddressFieldSpec.apt));
    });
  });

  group('AddressFieldSpec.toString', () {
    test('includes key and label', () {
      expect(
        AddressFieldSpec.apt.toString(),
        'AddressFieldSpec(key: apt, label: Apt / Suite / Unit)',
      );
    });
  });

  group('AddressFieldSpec presets', () {
    test('apt has expected defaults', () {
      expect(AddressFieldSpec.apt.key, 'apt');
      expect(AddressFieldSpec.apt.label, 'Apt / Suite / Unit');
      expect(AddressFieldSpec.apt.hint, 'e.g. Apt 4B');
      expect(AddressFieldSpec.apt.icon, Icons.home_outlined);
      expect(AddressFieldSpec.apt.required, isFalse);
      expect(AddressFieldSpec.apt.maxLines, 1);
    });

    test('floor has expected defaults', () {
      expect(AddressFieldSpec.floor.key, 'floor');
      expect(AddressFieldSpec.floor.label, 'Floor');
      expect(AddressFieldSpec.floor.hint, 'e.g. 3rd Floor');
      expect(AddressFieldSpec.floor.icon, Icons.layers_outlined);
    });

    test('deliveryNotes has maxLines 3', () {
      expect(AddressFieldSpec.deliveryNotes.key, 'deliveryNotes');
      expect(AddressFieldSpec.deliveryNotes.maxLines, 3);
      expect(AddressFieldSpec.deliveryNotes.icon, Icons.edit_note_outlined);
    });

    test('postalCode has prefillFrom', () {
      expect(AddressFieldSpec.postalCode.key, 'postalCode');
      expect(
        AddressFieldSpec.postalCode.prefillFrom,
        AddressAttribute.postalCode,
      );
    });

    test('defaults list contains apt, floor, deliveryNotes', () {
      expect(AddressFieldSpec.defaults, [
        AddressFieldSpec.apt,
        AddressFieldSpec.floor,
        AddressFieldSpec.deliveryNotes,
      ]);
    });
  });
}
