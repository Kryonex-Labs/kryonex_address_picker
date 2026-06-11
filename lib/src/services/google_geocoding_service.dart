import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../models/geocoding_result.dart';
import '../models/place_prediction.dart';
import '../models/structured_address.dart';
import 'geocoding_service.dart';

/// Geocoding via the Google Geocoding API.
///
/// Requires a valid Google Maps API key with the **Geocoding API** enabled.
/// See https://developers.google.com/maps/documentation/geocoding/overview
///
/// **Deprecated:** Use [GooglePlacesService] instead, which adds autocomplete
/// support via the Places API (New) while retaining the same Geocoding API
/// behaviour for [search] and [reverse].
@Deprecated('Use GooglePlacesService instead.')
class GoogleGeocodingService implements GeocodingService {
  GoogleGeocodingService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  /// Google Maps API key.
  final String apiKey;

  final http.Client _client;

  static const _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  @override
  Future<List<GeocodingResult>> search(
    String query, {
    List<String>? countryCodes,
    String? lang,
    int limit = 5,
  }) async {
    debugPrint('[AddressPicker] GoogleGeocoding.search: "$query"');
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{'address': query, 'key': apiKey};

      if (lang != null && lang.isNotEmpty) {
        params['language'] = lang;
      }

      if (countryCodes != null && countryCodes.isNotEmpty) {
        // Google uses `components=country:XX|country:YY` format.
        params['components'] = countryCodes
            .map((c) => 'country:${c.toUpperCase()}')
            .join('|');
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await _client.get(uri);
      debugPrint(
        '[AddressPicker] GoogleGeocoding.search.result: ${response.body}',
      );
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Google Geocoding API returned ${response.statusCode}',
          uri,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw http.ClientException('Google Geocoding API error: $status', uri);
      }

      final results = (data['results'] as List<dynamic>?) ?? <dynamic>[];

      return results
          .take(limit)
          .map(
            (e) =>
                GeocodingResult.fromGoogleResult(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e, trace) {
      debugPrint('[AddressPicker] GoogleGeocoding.search error: $e\n$trace');
      rethrow;
    }
  }

  @override
  Future<StructuredAddress?> reverse(double lat, double lon) async {
    debugPrint('[AddressPicker] GoogleGeocoding.reverse: ($lat, $lon)');

    try {
      final params = <String, String>{'latlng': '$lat,$lon', 'key': apiKey};

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Google Geocoding API returned ${response.statusCode}',
          uri,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') return null;

      final results = (data['results'] as List<dynamic>?) ?? <dynamic>[];
      if (results.isEmpty) return null;

      return GeocodingResult.fromGoogleResult(
        results.first as Map<String, dynamic>,
      ).toStructuredAddress();
    } catch (e, trace) {
      debugPrint('[AddressPicker] GoogleGeocoding.reverse error: $e\n$trace');
      rethrow;
    }
  }

  @override
  void dispose() {
    _client.close();
  }

  @override
  bool get supportsAutocomplete => false;

  @override
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    String? lang,
    int limit = 5,
  }) async => const [];

  @override
  Future<GeocodingResult?> placeDetails(String placeId) async => null;
}
