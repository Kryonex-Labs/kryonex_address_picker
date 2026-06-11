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

// ─── Google Geocoding API fixtures ──────────────────────────────────────────

/// A single, fully-populated Google Geocoding API result.
const Map<String, dynamic> googleResultFull = {
  'place_id': 'ChIJkbeSa_BfYzARphNChaFPjNc',
  'formatted_address':
      '12, Mahatma Gandhi Road, Bengaluru, Karnataka 560001, India',
  'geometry': {
    'location': {'lat': 12.9716, 'lng': 77.5946},
  },
  'address_components': [
    {
      'long_name': '12',
      'short_name': '12',
      'types': ['street_number'],
    },
    {
      'long_name': 'Mahatma Gandhi Road',
      'short_name': 'MG Road',
      'types': ['route'],
    },
    {
      'long_name': 'Bengaluru',
      'short_name': 'Bengaluru',
      'types': ['locality', 'political'],
    },
    {
      'long_name': 'Bengaluru Urban',
      'short_name': 'Bengaluru Urban',
      'types': ['administrative_area_level_2', 'political'],
    },
    {
      'long_name': 'Karnataka',
      'short_name': 'KA',
      'types': ['administrative_area_level_1', 'political'],
    },
    {
      'long_name': '560001',
      'short_name': '560001',
      'types': ['postal_code'],
    },
    {
      'long_name': 'India',
      'short_name': 'IN',
      'types': ['country', 'political'],
    },
  ],
};

/// A minimal Google result: geometry + formatted_address, empty components.
const Map<String, dynamic> googleResultMinimal = {
  'place_id': 'ChIJIQBpAG2ahYAR_6128GcTUEo',
  'formatted_address': 'San Francisco, CA, USA',
  'geometry': {
    'location': {'lat': 37.7749, 'lng': -122.4194},
  },
  'address_components': <dynamic>[],
};

/// Google Geocoding API response body with one result (status: OK).
String googleSearchBody({
  Map<String, dynamic> result = googleResultFull,
}) =>
    json.encode({'status': 'OK', 'results': [result]});

/// Google Geocoding API response body with zero results.
String googleEmptyBody() => json.encode({
      'status': 'ZERO_RESULTS',
      'results': <dynamic>[],
    });

/// Google Geocoding API error response body.
String googleErrorBody(String status) => json.encode({
      'status': status,
      'error_message': 'Something went wrong',
      'results': <dynamic>[],
    });

// ─── Model builders ─────────────────────────────────────────────────────────

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

// ─── Places API (New) fixtures ───────────────────────────────────────────────

/// A fully-populated Places API (New) autocomplete suggestion.
///
/// Mirrors the `suggestions[].placePrediction` shape returned by
/// `places:autocomplete`.
const Map<String, dynamic> placeSuggestionFull = {
  'placePrediction': {
    'placeId': 'ChIJdd4hrwug2EcRmSrV3Vo6llI',
    'text': {'text': '1 Main Street, London, UK'},
    'structuredFormat': {
      'mainText': {'text': '1 Main Street'},
      'secondaryText': {'text': 'London, UK'},
    },
  },
};

/// A Places API (New) autocomplete suggestion without a [secondaryText] entry.
const Map<String, dynamic> placeSuggestionNoSecondary = {
  'placePrediction': {
    'placeId': 'ChIJX9M6b8LcX4YReXFMoA',
    'text': {'text': 'MG Road'},
    'structuredFormat': {
      'mainText': {'text': 'MG Road'},
      // secondaryText absent — service falls back to ''.
    },
  },
};

/// Places API (New) autocomplete response body with one suggestion.
String placesAutocompleteBody({
  Map<String, dynamic> suggestion = placeSuggestionFull,
}) =>
    json.encode({
      'suggestions': [suggestion],
    });

/// Places API (New) autocomplete response with zero suggestions.
String placesEmptyAutocompleteBody() => json.encode({
      'suggestions': <dynamic>[],
    });

/// A fully-populated Places API (New) place details object.
///
/// Note the field-name differences from the Geocoding API:
/// - `location.latitude` / `location.longitude` (not `geometry.location`)
/// - `id` (not `place_id`)
/// - `addressComponents[].longText` / `shortText` (not `long_name` / `short_name`)
const Map<String, dynamic> placeDetailsFull = {
  'id': 'ChIJdd4hrwug2EcRmSrV3Vo6llI',
  'formattedAddress': '1 Main Street, London, EC1A 1BB, United Kingdom',
  'location': {'latitude': 51.5074, 'longitude': -0.1278},
  'addressComponents': [
    {
      'longText': '1',
      'shortText': '1',
      'types': ['street_number'],
    },
    {
      'longText': 'Main Street',
      'shortText': 'Main St',
      'types': ['route'],
    },
    {
      'longText': 'London',
      'shortText': 'London',
      'types': ['locality', 'political'],
    },
    {
      'longText': 'England',
      'shortText': 'England',
      'types': ['administrative_area_level_1', 'political'],
    },
    {
      'longText': 'EC1A 1BB',
      'shortText': 'EC1A 1BB',
      'types': ['postal_code'],
    },
    {
      'longText': 'United Kingdom',
      'shortText': 'GB',
      'types': ['country', 'political'],
    },
  ],
};

/// A minimal Places API (New) place details object: location + id only.
const Map<String, dynamic> placeDetailsMinimal = {
  'id': 'ChIJIQBpAG2ahYAR_6128GcTUEo',
  'formattedAddress': 'San Francisco, CA, USA',
  'location': {'latitude': 37.7749, 'longitude': -122.4194},
  'addressComponents': <dynamic>[],
};

/// Encodes a place details object as a JSON response body.
String placeDetailsBody({Map<String, dynamic> place = placeDetailsFull}) =>
    json.encode(place);
