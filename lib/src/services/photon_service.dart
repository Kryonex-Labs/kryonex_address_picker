import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/geocoding_result.dart';
import '../models/structured_address.dart';

/// Service for forward and reverse geocoding via the Photon API.
///
/// Uses the free [Komoot Photon](https://photon.komoot.io) service, which is
/// backed by OpenStreetMap data. No API key required.
///
/// Usage policy: no hard rate limit, but please avoid hammering the public
/// instance. The caller is responsible for debouncing search queries.
class PhotonService {
  PhotonService({
    http.Client? client,
    this.userAgent = 'kryonex_address_picker/0.1.0',
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// User-Agent header sent with every request.
  final String userAgent;

  static const _baseUrl = 'https://photon.komoot.io';

  Map<String, String> get _headers => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      };

  /// Forward geocode: search for addresses matching [query].
  ///
  /// [countryCodes] limits results to specific countries (ISO 3166-1 alpha-2,
  /// case-insensitive — they are uppercased internally as Photon requires).
  /// [lang] requests results in a specific language (e.g. `'en'`).
  /// [limit] controls the maximum number of results (default: 5).
  ///
  /// Returns an empty list on network errors or empty results.
  Future<List<GeocodingResult>> search(
    String query, {
    List<String>? countryCodes,
    String? lang,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    // Photon requires repeated `countrycode` params with uppercase values.
    final Map<String, List<String>> queryParams = {
      'q': [query],
      'limit': ['$limit'],
    };

    if (lang != null && lang.isNotEmpty) {
      queryParams['lang'] = [lang];
    }

    if (countryCodes != null && countryCodes.isNotEmpty) {
      queryParams['countrycode'] =
          countryCodes.map((c) => c.toUpperCase()).toList();
    }

    final uri = Uri(
      scheme: 'https',
      host: 'photon.komoot.io',
      path: '/api/',
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];
      return features
          .map((e) =>
              GeocodingResult.fromPhotonFeature(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Reverse geocode: resolve a lat/lng coordinate to an address.
  ///
  /// Returns `null` if the coordinate cannot be resolved.
  Future<StructuredAddress?> reverse(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(
      queryParameters: {
        'lat': '$lat',
        'lon': '$lon',
        'limit': '1',
      },
    );

    try {
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      if (features.isEmpty) return null;

      return GeocodingResult.fromPhotonFeature(
        features.first as Map<String, dynamic>,
      ).toStructuredAddress();
    } catch (_) {
      return null;
    }
  }

  /// Disposes the HTTP client.
  void dispose() {
    _client.close();
  }
}
