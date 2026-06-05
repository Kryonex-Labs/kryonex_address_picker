import 'address_field_spec.dart';

/// Fields available on the address detail screen.
///
/// Pass a subset to [AddressPickerConfig.detailFields] to control
/// which inputs appear. Order in the list determines display order.
@Deprecated(
  'Use AddressFieldSpec instead. AddressFieldSpec supports custom fields, '
  'icons, validation, keyboard types, and quick-fills. Call toSpec() to '
  'migrate an existing AddressDetailField. This enum will be removed in a '
  'future release.',
)
enum AddressDetailField {
  /// Apartment, suite, or unit number.
  apt,

  /// Floor / level.
  floor,

  /// Free-form delivery instructions.
  deliveryNotes;

  /// Human-readable label for the field.
  String get label {
    switch (this) {
      case AddressDetailField.apt:
        return 'Apt / Suite / Unit';
      case AddressDetailField.floor:
        return 'Floor';
      case AddressDetailField.deliveryNotes:
        return 'Delivery Notes';
    }
  }

  /// Hint text shown in the text field.
  String get hint {
    switch (this) {
      case AddressDetailField.apt:
        return 'e.g. Apt 4B';
      case AddressDetailField.floor:
        return 'e.g. 3rd Floor';
      case AddressDetailField.deliveryNotes:
        return 'e.g. Leave at the door';
    }
  }

  /// Bridges this legacy field to its equivalent [AddressFieldSpec] preset.
  AddressFieldSpec toSpec() {
    switch (this) {
      case AddressDetailField.apt:
        return AddressFieldSpec.apt;
      case AddressDetailField.floor:
        return AddressFieldSpec.floor;
      case AddressDetailField.deliveryNotes:
        return AddressFieldSpec.deliveryNotes;
    }
  }
}
