import 'dart:convert';

import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:latlong2/latlong.dart';

/// Test fixtures: canonical Photon payloads and model builders.
///
/// Keep the JSON here as close to real Photon responses as possible so the
/// parsing tests assert against realistic data.

/// A single, fully-populated Photon GeoJSON `Feature`.
///
/// Note GeoJSON coordinate order is `[lon, lat]` and Photon returns an
/// uppercase `countrycode`.
const Map<String, dynamic> photonFeatureFull = {
  'type': 'Feature',
  'geometry': {
    'type': 'Point',
    'coordinates': [77.5946, 12.9716], // [lon, lat] → Bengaluru
  },
  'properties': {
    'osm_id': 123456,
    'name': 'MG Road',
    'housenumber': '12',
    'street': 'Mahatma Gandhi Road',
    'city': 'Bengaluru',
    'district': 'Bengaluru Urban',
    'state': 'Karnataka',
    'postcode': '560001',
    'country': 'India',
    'countrycode': 'IN',
    'type': 'street',
  },
};

/// A minimal Photon feature: geometry plus a single name property.
const Map<String, dynamic> photonFeatureMinimal = {
  'type': 'Feature',
  'geometry': {
    'type': 'Point',
    'coordinates': [-122.4194, 37.7749], // San Francisco
  },
  'properties': {
    'name': 'Somewhere',
  },
};

/// A full Photon `FeatureCollection` body (as a JSON string) with one feature.
String photonSearchBody({Map<String, dynamic> feature = photonFeatureFull}) =>
    json.encode({
      'type': 'FeatureCollection',
      'features': [feature],
    });

/// A Photon `FeatureCollection` body with no features.
String photonEmptyBody() => json.encode({
      'type': 'FeatureCollection',
      'features': <dynamic>[],
    });

/// Malformed JSON that should make the service swallow the error.
const String malformedBody = '{ this is not valid json';

/// Builds a [StructuredAddress] with sensible defaults for tests.
StructuredAddress buildAddress({
  String displayName = 'Mahatma Gandhi Road, Bengaluru, Karnataka, India',
  LatLng? latLng,
  String? street = 'Mahatma Gandhi Road',
  String? houseNumber = '12',
  String? city = 'Bengaluru',
  String? state = 'Karnataka',
  String? postalCode = '560001',
  String? country = 'India',
  String? countryCode = 'in',
}) {
  return StructuredAddress(
    displayName: displayName,
    latLng: latLng ?? const LatLng(12.9716, 77.5946),
    street: street,
    houseNumber: houseNumber,
    city: city,
    state: state,
    postalCode: postalCode,
    country: country,
    countryCode: countryCode,
  );
}

/// Builds a [SelectedAddress] wrapping [buildAddress] plus optional details.
SelectedAddress buildSelectedAddress({
  StructuredAddress? address,
  AddressDetails? details,
}) {
  return SelectedAddress(
    address: address ?? buildAddress(),
    details: details,
  );
}
