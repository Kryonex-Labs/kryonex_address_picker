import 'package:latlong2/latlong.dart';

/// A fully parsed address with geographic coordinates.
///
/// Fields are parsed from Nominatim's `address` object. Any field that
/// could not be resolved from the raw response will be `null`.
class StructuredAddress {
  const StructuredAddress({
    required this.displayName,
    required this.latLng,
    this.street,
    this.houseNumber,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.countryCode,
  });

  /// The full, human-readable address string from Nominatim.
  final String displayName;

  /// Geographic coordinates of the address.
  final LatLng latLng;

  /// Street name (e.g. "Main Street").
  final String? street;

  /// House / building number (e.g. "123").
  final String? houseNumber;

  /// City, town, or village name.
  final String? city;

  /// State or province.
  final String? state;

  /// Postal / ZIP code.
  final String? postalCode;

  /// Full country name (e.g. "United States").
  final String? country;

  /// ISO 3166-1 alpha-2 country code (e.g. "us").
  final String? countryCode;

  /// Primary display line — street with house number when available.
  String get primaryLine {
    final parts = <String>[
      if (houseNumber != null) houseNumber!,
      if (street != null) street!,
    ];
    return parts.isNotEmpty ? parts.join(' ') : displayName.split(',').first;
  }

  /// Secondary display line — city, state, postal code.
  String get secondaryLine {
    final parts = <String>[
      if (city != null) city!,
      if (state != null) state!,
      if (postalCode != null) postalCode!,
    ];
    return parts.join(', ');
  }

  /// Creates a copy with the given fields replaced.
  StructuredAddress copyWith({
    String? displayName,
    LatLng? latLng,
    String? street,
    String? houseNumber,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? countryCode,
  }) {
    return StructuredAddress(
      displayName: displayName ?? this.displayName,
      latLng: latLng ?? this.latLng,
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  /// Serializes to JSON map for local persistence.
  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'latitude': latLng.latitude,
        'longitude': latLng.longitude,
        'street': street,
        'houseNumber': houseNumber,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
        'countryCode': countryCode,
      };

  /// Deserializes from JSON map.
  factory StructuredAddress.fromJson(Map<String, dynamic> json) {
    return StructuredAddress(
      displayName: json['displayName'] as String,
      latLng: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      street: json['street'] as String?,
      houseNumber: json['houseNumber'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredAddress &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          latLng == other.latLng;

  @override
  int get hashCode => displayName.hashCode ^ latLng.hashCode;

  @override
  String toString() => 'StructuredAddress($displayName)';
}
