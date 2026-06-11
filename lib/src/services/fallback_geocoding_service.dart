import 'package:flutter/foundation.dart';

import '../models/geocoding_result.dart';
import '../models/place_prediction.dart';
import '../models/structured_address.dart';
import 'geocoding_service.dart';

/// Wraps a [primary] geocoding service with automatic fallback to [fallback].
///
/// If the primary service throws on [search] or [reverse], the exception is
/// silently caught and the request is retried against the fallback. This is
/// the default behaviour when a Google API key is provided: Google is tried
/// first; if it fails for any reason, Photon handles the request.
///
/// Autocomplete ([supportsAutocomplete], [autocomplete], [placeDetails]) is
/// delegated exclusively to the primary service — there is no Photon fallback
/// for these since Photon does not expose a compatible autocomplete endpoint.
class FallbackGeocodingService implements GeocodingService {
  FallbackGeocodingService({
    required this.primary,
    required this.fallback,
  });

  /// Service tried first.
  final GeocodingService primary;

  /// Service used when [primary] throws on [search] or [reverse].
  final GeocodingService fallback;

  @override
  Future<List<GeocodingResult>> search(
    String query, {
    List<String>? countryCodes,
    String? lang,
    int limit = 5,
  }) async {
    try {
      return await primary.search(
        query,
        countryCodes: countryCodes,
        lang: lang,
        limit: limit,
      );
    } catch (e) {
      debugPrint('[AddressPicker] Primary failed ($e), falling back for search("$query")');
      return fallback.search(
        query,
        countryCodes: countryCodes,
        lang: lang,
        limit: limit,
      );
    }
  }

  @override
  Future<StructuredAddress?> reverse(double lat, double lon) async {
    try {
      return await primary.reverse(lat, lon);
    } catch (e) {
      debugPrint('[AddressPicker] Primary failed ($e), falling back for reverse($lat, $lon)');
      return fallback.reverse(lat, lon);
    }
  }

  @override
  void dispose() {
    primary.dispose();
    fallback.dispose();
  }

  // ─── Autocomplete (primary only, no Photon fallback) ────────────────────────

  @override
  bool get supportsAutocomplete => primary.supportsAutocomplete;

  @override
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    String? lang,
    int limit = 5,
  }) async {
    try {
      return await primary.autocomplete(input, lang: lang, limit: limit);
    } catch (e) {
      debugPrint(
        '[AddressPicker] Primary failed ($e), autocomplete has no fallback',
      );
      rethrow;
    }
  }

  @override
  Future<GeocodingResult?> placeDetails(String placeId) async {
    try {
      return await primary.placeDetails(placeId);
    } catch (e) {
      debugPrint(
        '[AddressPicker] Primary failed ($e), placeDetails has no fallback',
      );
      rethrow;
    }
  }
}
