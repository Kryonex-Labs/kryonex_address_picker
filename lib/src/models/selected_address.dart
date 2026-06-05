import 'structured_address.dart';
import 'address_details.dart';

/// The composite result returned by the address picker.
///
/// Contains the geocoded [address] and optional [details] collected
/// on the detail screen. If [AddressPickerConfig.showDetailScreen] is
/// `false`, [details] will be `null`.
class SelectedAddress {
  const SelectedAddress({
    required this.address,
    this.details,
  });

  /// The geocoded, structured address.
  final StructuredAddress address;

  /// Optional delivery details (apt, floor, notes).
  final AddressDetails? details;

  /// Creates a copy with the given fields replaced.
  SelectedAddress copyWith({
    StructuredAddress? address,
    AddressDetails? details,
  }) {
    return SelectedAddress(
      address: address ?? this.address,
      details: details ?? this.details,
    );
  }

  /// Serializes to JSON map for local persistence.
  Map<String, dynamic> toJson() => {
        'address': address.toJson(),
        'details': details?.toJson(),
      };

  /// Deserializes from JSON map.
  factory SelectedAddress.fromJson(Map<String, dynamic> json) {
    return SelectedAddress(
      address: StructuredAddress.fromJson(
        json['address'] as Map<String, dynamic>,
      ),
      details: json['details'] != null
          ? AddressDetails.fromJson(json['details'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedAddress &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          details == other.details;

  @override
  int get hashCode => address.hashCode ^ details.hashCode;

  @override
  String toString() => 'SelectedAddress($address, details: $details)';
}
