import 'structured_address.dart';

/// Attributes captured on a confirmed [StructuredAddress].
///
/// Pass one of these as [AddressFieldSpec.prefillFrom] to have the detail
/// sheet pre-populate that field from the address the user just confirmed
/// on the map.
enum AddressAttribute {
  /// Full human-readable address string ([StructuredAddress.displayName]).
  displayName,

  /// Street name ([StructuredAddress.street]).
  street,

  /// House / building number ([StructuredAddress.houseNumber]).
  houseNumber,

  /// City, town, or village ([StructuredAddress.city]).
  city,

  /// State or province ([StructuredAddress.state]).
  state,

  /// Postal / ZIP code ([StructuredAddress.postalCode]).
  postalCode,

  /// Full country name ([StructuredAddress.country]).
  country,

  /// ISO 3166-1 alpha-2 country code ([StructuredAddress.countryCode]).
  countryCode,

  /// Latitude ([StructuredAddress.latLng]).
  latitude,

  /// Longitude ([StructuredAddress.latLng]).
  longitude,

  /// Composed "house number + street" line ([StructuredAddress.primaryLine]).
  primaryLine,

  /// Composed "city, state, postal" line ([StructuredAddress.secondaryLine]).
  secondaryLine,
}

/// Reads [AddressAttribute] values off a [StructuredAddress] as a string.
extension AddressAttributeReader on StructuredAddress {
  /// Returns the value of [attribute] on this address, or `null` when the
  /// underlying field is absent. Numeric attributes are stringified.
  String? readAttribute(AddressAttribute attribute) {
    switch (attribute) {
      case AddressAttribute.displayName:
        return displayName;
      case AddressAttribute.street:
        return street;
      case AddressAttribute.houseNumber:
        return houseNumber;
      case AddressAttribute.city:
        return city;
      case AddressAttribute.state:
        return state;
      case AddressAttribute.postalCode:
        return postalCode;
      case AddressAttribute.country:
        return country;
      case AddressAttribute.countryCode:
        return countryCode;
      case AddressAttribute.latitude:
        return latLng.latitude.toString();
      case AddressAttribute.longitude:
        return latLng.longitude.toString();
      case AddressAttribute.primaryLine:
        return primaryLine;
      case AddressAttribute.secondaryLine:
        return secondaryLine;
    }
  }
}
