import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../models/geocoding_result.dart';
import '../models/place_prediction.dart';
import '../models/structured_address.dart';
import 'geocoding_service.dart';

/// Geocoding via the **Places API (New)** for autocomplete and the
/// **Google Geocoding API** for forward and reverse geocoding.
///
/// Requires a valid Google Maps API key with both APIs enabled:
/// - **Places API (New)**: `places-backend.googleapis.com`
/// - **Geocoding API**: `geocoding-backend.googleapis.com`
///
/// See:
/// - https://developers.google.com/maps/documentation/places/web-service/autocomplete
/// - https://developers.google.com/maps/documentation/geocoding/overview
class GooglePlacesService implements GeocodingService {
  GooglePlacesService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client(),
      _sessionToken = _generateSessionToken();

  /// Google Maps API key.
  final String apiKey;

  final http.Client _client;

  /// Current session token. Auto-reset after [placeDetails] is called.
  String _sessionToken;

  static const _geocodingBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const _autocompleteUrl =
      'https://places.googleapis.com/v1/places:autocomplete';
  static const _placesBaseUrl = 'https://places.googleapis.com/v1/places';

  // ─── Autocomplete ──────────────────────────────────────────────────────────

  @override
  bool get supportsAutocomplete => true;

  @override
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    String? lang,
    int limit = 5,
  }) async {
    debugPrint('[AddressPicker] GooglePlaces.autocomplete: "$input"');
    if (input.trim().isEmpty) return [];

    try {
      final body = <String, dynamic>{
        'input': input,
        'sessionToken': _sessionToken,
      };
      if (lang != null && lang.isNotEmpty) {
        body['languageCode'] = lang;
      }

      final uri = Uri.parse(_autocompleteUrl);
      final response = await _client.post(
        uri,
        headers: {'X-Goog-Api-Key': apiKey, 'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      debugPrint(
        '[AddressPicker] GooglePlaces.autocomplete.result: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw http.ClientException(
          'Places API autocomplete returned ${response.statusCode}',
          uri,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final suggestions =
          (data['suggestions'] as List<dynamic>?) ?? <dynamic>[];

      return suggestions.take(limit).map((s) {
        final pred =
            (s as Map<String, dynamic>)['placePrediction']
                as Map<String, dynamic>;
        final mainText =
            (pred['structuredFormat'] as Map<String, dynamic>?)?['mainText']
                as Map<String, dynamic>?;
        final secondaryText =
            (pred['structuredFormat']
                as Map<String, dynamic>?)?['secondaryText']
                as Map<String, dynamic>?;
        final fullText =
            (pred['text'] as Map<String, dynamic>?)?['text'] as String? ?? '';
        return PlacePrediction(
          placeId: pred['placeId'] as String,
          mainText: mainText?['text'] as String? ?? fullText,
          secondaryText: secondaryText?['text'] as String? ?? '',
          fullText: fullText,
        );
      }).toList();
    } catch (e, trace) {
      debugPrint('[AddressPicker] GooglePlaces.autocomplete error: $e\n$trace');
      rethrow;
    }
  }

  @override
  Future<GeocodingResult?> placeDetails(String placeId) async {
    try {
      final uri = Uri.parse(
        '$_placesBaseUrl/$placeId',
      ).replace(queryParameters: {'sessionToken': _sessionToken});

      final response = await _client.get(
        uri,
        headers: {
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location,addressComponents',
        },
      );

      // Always reset session token after a placeDetails call (success or error).
      _sessionToken = _generateSessionToken();

      if (response.statusCode != 200) {
        throw http.ClientException(
          'Places API placeDetails returned ${response.statusCode}',
          uri,
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return GeocodingResult.fromGooglePlaceDetails(data);
    } catch (e, trace) {
      // HTTP-level errors (non-200) are intentional — let them propagate so
      // callers can distinguish "request failed" from "parse error returned null".
      if (e is http.ClientException) rethrow;
      debugPrint('Error: $e\nStackTrace: $trace');
      return null;
    }
  }

  // ─── Forward geocoding (Google Geocoding API) ───────────────────────────────

  @override
  Future<List<GeocodingResult>> search(
    String query, {
    List<String>? countryCodes,
    String? lang,
    int limit = 5,
  }) async {
    debugPrint('[AddressPicker] GooglePlaces.search: "$query"');
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{'address': query, 'key': apiKey};

      if (lang != null && lang.isNotEmpty) {
        params['language'] = lang;
      }

      if (countryCodes != null && countryCodes.isNotEmpty) {
        params['components'] = countryCodes
            .map((c) => 'country:${c.toUpperCase()}')
            .join('|');
      }

      final uri = Uri.parse(_geocodingBaseUrl).replace(queryParameters: params);

      final response = await _client.get(uri);
      debugPrint('[AddressPicker] GooglePlaces.search.result: ${response.body}');

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
      debugPrint('[AddressPicker] GooglePlaces.search error: $e\n$trace');
      rethrow;
    }
  }

  // ─── Reverse geocoding (Google Geocoding API) ───────────────────────────────

  @override
  Future<StructuredAddress?> reverse(double lat, double lon) async {
    debugPrint('[AddressPicker] GooglePlaces.reverse: ($lat, $lon)');

    try {
      final params = <String, String>{'latlng': '$lat,$lon', 'key': apiKey};

      final uri = Uri.parse(_geocodingBaseUrl).replace(queryParameters: params);

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
      debugPrint('[AddressPicker] GooglePlaces.reverse error: $e\n$trace');
      rethrow;
    }
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _client.close();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Generates a random UUID v4 string for use as a Places API session token.
  static String _generateSessionToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // Set version 4 bits: version = 4 (0100xxxx), variant = 10xxxxxx.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}
