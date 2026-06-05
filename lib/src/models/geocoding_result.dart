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

  /// OSM place identifier (sourced from `osm_id` in Photon responses).
  final int placeId;

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
      placeId: (props['osm_id'] as num?)?.toInt() ?? 0,
      displayName: displayName,
      lat: lat,
      lon: lon,
      addressParts: addressParts,
      type: props['type'] as String?,
      importance: null, // Photon does not expose an importance score.
    );
  }

  @override
  String toString() => 'GeocodingResult($displayName)';
}
