/// Additional delivery details for an address.
///
/// Collected on the detail screen after map confirmation.
/// All fields are optional — the consumer decides which to display
/// via [AddressDetailField].
class AddressDetails {
  const AddressDetails({
    this.apt,
    this.floor,
    this.deliveryNotes,
  });

  /// Apartment, suite, or unit number.
  final String? apt;

  /// Floor / level.
  final String? floor;

  /// Free-form delivery instructions.
  final String? deliveryNotes;

  /// Whether any detail field has been filled in.
  bool get isEmpty => apt == null && floor == null && deliveryNotes == null;

  /// Whether at least one detail field has a value.
  bool get isNotEmpty => !isEmpty;

  /// Creates a copy with the given fields replaced.
  AddressDetails copyWith({
    String? apt,
    String? floor,
    String? deliveryNotes,
  }) {
    return AddressDetails(
      apt: apt ?? this.apt,
      floor: floor ?? this.floor,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'apt': apt,
        'floor': floor,
        'deliveryNotes': deliveryNotes,
      };

  /// Deserializes from JSON map.
  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      apt: json['apt'] as String?,
      floor: json['floor'] as String?,
      deliveryNotes: json['deliveryNotes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressDetails &&
          runtimeType == other.runtimeType &&
          apt == other.apt &&
          floor == other.floor &&
          deliveryNotes == other.deliveryNotes;

  @override
  int get hashCode => apt.hashCode ^ floor.hashCode ^ deliveryNotes.hashCode;

  @override
  String toString() =>
      'AddressDetails(apt: $apt, floor: $floor, notes: $deliveryNotes)';
}
