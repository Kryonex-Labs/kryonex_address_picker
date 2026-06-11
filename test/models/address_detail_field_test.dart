import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  // ignore: deprecated_member_use_from_same_package
  group('AddressDetailField (deprecated)', () {
    group('label', () {
      test('apt returns "Apt / Suite / Unit"', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.apt.label, 'Apt / Suite / Unit');
      });

      test('floor returns "Floor"', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.floor.label, 'Floor');
      });

      test('deliveryNotes returns "Delivery Notes"', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.deliveryNotes.label, 'Delivery Notes');
      });
    });

    group('hint', () {
      test('apt returns "e.g. Apt 4B"', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.apt.hint, 'e.g. Apt 4B');
      });

      test('floor returns "e.g. 3rd Floor"', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.floor.hint, 'e.g. 3rd Floor');
      });

      test('deliveryNotes returns "e.g. Leave at the door"', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.deliveryNotes.hint, 'e.g. Leave at the door');
      });
    });

    group('toSpec', () {
      test('apt maps to AddressFieldSpec.apt', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.apt.toSpec(), AddressFieldSpec.apt);
      });

      test('floor maps to AddressFieldSpec.floor', () {
        // ignore: deprecated_member_use_from_same_package
        expect(AddressDetailField.floor.toSpec(), AddressFieldSpec.floor);
      });

      test('deliveryNotes maps to AddressFieldSpec.deliveryNotes', () {
        // ignore: deprecated_member_use_from_same_package
        expect(
          AddressDetailField.deliveryNotes.toSpec(),
          AddressFieldSpec.deliveryNotes,
        );
      });
    });
  });
}
