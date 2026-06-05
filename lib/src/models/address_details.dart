/// Additional delivery details for an address.
///
/// Collected on the detail sheet after map confirmation. Values are stored in
/// a keyed [values] map, where each key is an [AddressFieldSpec.key]. This lets
/// consumers define arbitrary custom fields beyond the built-in apt / floor /
/// delivery-notes set.
///
/// The legacy [apt], [floor], and [deliveryNotes] getters remain available as
/// convenience accessors over [values].
class AddressDetails {
  /// Creates details from a keyed [values] map.
  const AddressDetails.fromValues(this.values);

  /// Convenience constructor for the three built-in fields.
  ///
  /// Prefer [AddressDetails.fromValues] for custom field sets.
  AddressDetails({
    String? apt,
    String? floor,
    String? deliveryNotes,
  }) : values = {
          if (apt != null) 'apt': apt,
          if (floor != null) 'floor': floor,
          if (deliveryNotes != null) 'deliveryNotes': deliveryNotes,
        };

  /// All collected field values, keyed by [AddressFieldSpec.key].
  ///
  /// Empty fields are omitted (not stored as `null`).
  final Map<String, String?> values;

  /// Apartment, suite, or unit number (built-in `apt` field).
  String? get apt => values['apt'];

  /// Floor / level (built-in `floor` field).
  String? get floor => values['floor'];

  /// Free-form delivery instructions (built-in `deliveryNotes` field).
  String? get deliveryNotes => values['deliveryNotes'];

  /// The value for an arbitrary field [key], or `null` if not present.
  String? operator [](String key) => values[key];

  /// Whether no detail field has been filled in.
  bool get isEmpty => values.values.every((v) => v == null || v.isEmpty);

  /// Whether at least one detail field has a value.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy, merging [values] over the existing entries.
  AddressDetails copyWith({Map<String, String?>? values}) {
    return AddressDetails.fromValues({
      ...this.values,
      if (values != null) ...values,
    });
  }

  /// Serializes to a JSON map (the raw [values]).
  Map<String, dynamic> toJson() => {...values};

  /// Deserializes from a JSON map.
  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails.fromValues({
      for (final entry in json.entries) entry.key: entry.value as String?,
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressDetails &&
          runtimeType == other.runtimeType &&
          _mapEquals(values, other.values);

  @override
  int get hashCode {
    // Order-independent hash over the entries.
    var hash = 0;
    for (final entry in values.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() => 'AddressDetails($values)';

  static bool _mapEquals(Map<String, String?> a, Map<String, String?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
