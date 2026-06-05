import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, TextInputAction;

/// Describes a single editable field on the address detail sheet.
///
/// Specs are fully composable: combine the built-in presets ([apt], [floor],
/// [deliveryNotes]) with your own custom fields, in any order, and pass the
/// list to [AddressPickerConfig.detailFields].
///
/// ```dart
/// AddressPickerConfig(
///   detailFields: [
///     AddressFieldSpec.apt,
///     AddressFieldSpec.floor,
///     AddressFieldSpec(
///       key: 'gate',
///       label: 'Gate code',
///       icon: Icons.pin,
///       keyboardType: TextInputType.number,
///       required: true,
///       quickFills: ['A', 'B', 'C'],
///     ),
///   ],
/// );
/// ```
///
/// Each field's [key] becomes the key under which its value is stored in
/// [AddressDetails.values].
@immutable
class AddressFieldSpec {
  const AddressFieldSpec({
    required this.key,
    required this.label,
    this.hint,
    this.icon,
    this.required = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.quickFills,
  }) : assert(maxLines > 0, 'maxLines must be greater than zero');

  /// Stable identifier. Used as the key in [AddressDetails.values] and as the
  /// widget key for the field, so it must be unique within a field list.
  final String key;

  /// Human-readable label shown above the input.
  final String label;

  /// Placeholder text shown when the field is empty.
  final String? hint;

  /// Optional leading icon.
  final IconData? icon;

  /// When `true`, the field must be non-empty before the sheet can be saved.
  final bool required;

  /// Maximum number of input lines. Values greater than 1 render a multi-line
  /// text area (e.g. delivery notes).
  final int maxLines;

  /// Optional maximum character count.
  final int? maxLength;

  /// Keyboard type for the input.
  final TextInputType keyboardType;

  /// Optional keyboard action button.
  final TextInputAction? textInputAction;

  /// Optional custom validator. Return a non-null error string to block save.
  /// Runs in addition to the [required] check.
  final String? Function(String? value)? validator;

  /// Optional quick-fill suggestions rendered as tappable chips below the
  /// field. Tapping a chip sets the field's value.
  final List<String>? quickFills;

  /// Apartment, suite, or unit number. Mirrors the original built-in field.
  static const AddressFieldSpec apt = AddressFieldSpec(
    key: 'apt',
    label: 'Apt / Suite / Unit',
    hint: 'e.g. Apt 4B',
    icon: Icons.home_outlined,
  );

  /// Floor / level. Mirrors the original built-in field.
  static const AddressFieldSpec floor = AddressFieldSpec(
    key: 'floor',
    label: 'Floor',
    hint: 'e.g. 3rd Floor',
    icon: Icons.layers_outlined,
  );

  /// Free-form delivery instructions. Mirrors the original built-in field.
  static const AddressFieldSpec deliveryNotes = AddressFieldSpec(
    key: 'deliveryNotes',
    label: 'Delivery Notes',
    hint: 'e.g. Leave at the door',
    icon: Icons.edit_note_outlined,
    maxLines: 3,
  );

  /// Postal Code / ZIP Code. Not included by default since it's often captured in the
  /// main address line, but commonly needed for international addresses.
  static const AddressFieldSpec postalCode = AddressFieldSpec(
    key: 'postalCode',
    label: 'Postal Code',
    hint: 'e.g. 12345',
    icon: Icons.local_post_office_outlined,
    keyboardType: TextInputType.text,
  );

  /// The default set of fields, used when no custom list is configured.
  static const List<AddressFieldSpec> defaults = [apt, floor, deliveryNotes];

  /// Validates [value] against [required] and [validator].
  ///
  /// Returns the first error message, or `null` when the value is acceptable.
  String? validate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (required && trimmed.isEmpty) {
      return '$label is required';
    }
    return validator?.call(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressFieldSpec &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'AddressFieldSpec(key: $key, label: $label)';
}
