import 'package:latlong2/latlong.dart';

import 'structured_address.dart';

/// Raw geocoding API response, lightly typed.
///
/// Used internally by [PhotonService]. Consumers interact with
/// [StructuredAddress] instead.
class GeocodingResult {
  const GeocodingResult({
    required this.placeId,
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.addressParts,
    this.type,
    this.importance,
  });

  /// Provider-specific place identifier.
  ///
  /// For Photon this is the stringified `osm_id`; for Google it is the
  /// opaque `place_id` string returned by the Geocoding API.
  final String placeId;

  /// Full human-readable address string.
  final String displayName;

  /// Latitude coordinate.
  final double lat;

  /// Longitude coordinate.
  final double lon;

  /// Address parts with Nominatim-compatible keys:
  /// `house_number`, `road`, `city`, `postcode`, `state`, `country`,
  /// `country_code` (lowercase).
  final Map<String, dynamic> addressParts;

  /// Place type (e.g. "house", "street", "city").
  final String? type;

  /// Relevance score (not available from Photon; always `null`).
  final double? importance;

  /// Convenience accessor for [LatLng].
  LatLng get latLng => LatLng(lat, lon);

  /// Converts the raw result into a [StructuredAddress].
  StructuredAddress toStructuredAddress() {
    final addr = addressParts;
    return StructuredAddress(
      displayName: displayName,
      latLng: latLng,
      houseNumber: addr['house_number'] as String?,
      street: addr['road'] as String?,
      city: (addr['city'] ?? addr['town'] ?? addr['village']) as String?,
      state: addr['state'] as String?,
      postalCode: addr['postcode'] as String?,
      country: addr['country'] as String?,
      countryCode: addr['country_code'] as String?,
    );
  }

  /// Parses a single GeoJSON Feature from a Photon API response.
  ///
  /// Photon returns a `FeatureCollection`; pass each element of `features`
  /// to this factory. Coordinates are in GeoJSON order `[lon, lat]`.
  factory GeocodingResult.fromPhotonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List<dynamic>;
    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    final props = (feature['properties'] as Map<String, dynamic>?) ?? {};

    // Build a human-readable display name from available fields.
    final nameParts = <String>[
      if (props['name'] != null) props['name'] as String,
      if (props['street'] != null) props['street'] as String,
      if (props['city'] != null) props['city'] as String,
      if (props['state'] != null) props['state'] as String,
      if (props['country'] != null) props['country'] as String,
    ];
    final displayName =
        nameParts.isNotEmpty ? nameParts.join(', ') : 'Unknown location';

    // Normalize Photon property keys to Nominatim-compatible addressParts keys
    // so that toStructuredAddress() works without modification.
    final addressParts = <String, dynamic>{
      if (props['housenumber'] != null)
        'house_number': props['housenumber'] as String,
      if (props['street'] != null) 'road': props['street'] as String,
      if (props['city'] != null) 'city': props['city'] as String,
      if (props['district'] != null) 'town': props['district'] as String,
      if (props['postcode'] != null) 'postcode': props['postcode'] as String,
      if (props['state'] != null) 'state': props['state'] as String,
      if (props['country'] != null) 'country': props['country'] as String,
      // Photon returns uppercase country codes (e.g. "IN"); normalise to lower.
      if (props['countrycode'] != null)
        'country_code':
            (props['countrycode'] as String).toLowerCase(),
    };

    return GeocodingResult(
      placeId: (props['osm_id'] as num?)?.toInt().toString() ?? '0',
      displayName: displayName,
      lat: lat,
      lon: lon,
      addressParts: addressParts,
      type: props['type'] as String?,
      importance: null, // Photon does not expose an importance score.
    );
  }

  /// Parses a single result object from a Google Geocoding API response.
  ///
  /// Google returns `{ results: [ ... ] }`; pass each element to this factory.
  /// Address-component types are mapped to Nominatim-compatible keys so that
  /// [toStructuredAddress] works without modification.
  factory GeocodingResult.fromGoogleResult(Map<String, dynamic> result) {
    final geometry = result['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    final lat = (location['lat'] as num).toDouble();
    final lng = (location['lng'] as num).toDouble();

    final formattedAddress =
        (result['formatted_address'] as String?) ?? 'Unknown location';
    final placeId = (result['place_id'] as String?) ?? '';

    final components =
        (result['address_components'] as List<dynamic>?) ?? <dynamic>[];

    // Map Google address-component types → Nominatim-compatible keys.
    const typeMapping = <String, String>{
      'street_number': 'house_number',
      'route': 'road',
      'locality': 'city',
      'sublocality': 'town',
      'administrative_area_level_1': 'state',
      'postal_code': 'postcode',
      'country': 'country',
    };

    final addressParts = <String, dynamic>{};
    String? countryCode;

    for (final comp in components) {
      final map = comp as Map<String, dynamic>;
      final types = (map['types'] as List<dynamic>).cast<String>();
      final longName = map['long_name'] as String?;
      final shortName = map['short_name'] as String?;

      for (final type in types) {
        final nominatimKey = typeMapping[type];
        if (nominatimKey != null && longName != null) {
          addressParts[nominatimKey] = longName;
        }
        if (type == 'country' && shortName != null) {
          countryCode = shortName.toLowerCase();
        }
      }
    }
    if (countryCode != null) {
      addressParts['country_code'] = countryCode;
    }

    return GeocodingResult(
      placeId: placeId,
      displayName: formattedAddress,
      lat: lat,
      lon: lng,
      addressParts: addressParts,
      type: null,
      importance: null,
    );
  }

  @override
  String toString() => 'GeocodingResult($displayName)';

  /// Parses a single place object from a Places API (New) place details
  /// response.
  ///
  /// The response shape differs from [fromGoogleResult] in three ways:
  /// - `location.latitude` / `location.longitude` (not `geometry.location`)
  /// - `id` (not `place_id`)
  /// - `addressComponents[{longText, shortText, types}]`
  ///   (not `address_components[{long_name, short_name, types}]`)
  factory GeocodingResult.fromGooglePlaceDetails(
    Map<String, dynamic> place,
  ) {
    final locationMap = place['location'] as Map<String, dynamic>;
    final lat = (locationMap['latitude'] as num).toDouble();
    final lng = (locationMap['longitude'] as num).toDouble();

    final placeId = (place['id'] as String?) ?? '';
    final formattedAddress =
        (place['formattedAddress'] as String?) ??
        ((place['displayName'] as Map<String, dynamic>?)?['text'] as String?) ??
        'Unknown location';

    final components =
        (place['addressComponents'] as List<dynamic>?) ?? <dynamic>[];

    // Map Places API (New) address-component types → Nominatim-compatible keys.
    // The type identifiers are identical to the Geocoding API; only the field
    // names on the component object differ (longText vs long_name).
    const typeMapping = <String, String>{
      'street_number': 'house_number',
      'route': 'road',
      'locality': 'city',
      'sublocality': 'town',
      'administrative_area_level_1': 'state',
      'postal_code': 'postcode',
      'country': 'country',
    };

    final addressParts = <String, dynamic>{};
    String? countryCode;

    for (final comp in components) {
      final map = comp as Map<String, dynamic>;
      final types =
          (map['types'] as List<dynamic>?)?.cast<String>() ?? <String>[];
      final longText = map['longText'] as String?;
      final shortText = map['shortText'] as String?;

      for (final type in types) {
        final nominatimKey = typeMapping[type];
        if (nominatimKey != null && longText != null) {
          addressParts[nominatimKey] = longText;
        }
        if (type == 'country' && shortText != null) {
          countryCode = shortText.toLowerCase();
        }
      }
    }
    if (countryCode != null) {
      addressParts['country_code'] = countryCode;
    }

    return GeocodingResult(
      placeId: placeId,
      displayName: formattedAddress,
      lat: lat,
      lon: lng,
      addressParts: addressParts,
      type: null,
      importance: null,
    );
  }
}
