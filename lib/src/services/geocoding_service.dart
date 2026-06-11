import '../models/geocoding_result.dart';
import '../models/place_prediction.dart';
import '../models/structured_address.dart';

/// Provider-agnostic geocoding contract.
///
/// Implement this to plug in any geocoding backend (Google, Mapbox, etc.).
/// The package ships [PhotonService] (free, no key) and
/// [GooglePlacesService] (requires API key) out of the box.
abstract class GeocodingService {
  /// Forward-geocode a free-text [query] into ranked results.
  ///
  /// [countryCodes] – ISO 3166-1 alpha-2 codes to bias results.
  /// [lang] – BCP-47 language tag for result localisation.
  /// [limit] – maximum number of results to return.
  Future<List<GeocodingResult>> search(
    String query, {
    List<String>? countryCodes,
    String? lang,
    int limit = 5,
  });

  /// Reverse-geocode a coordinate pair into a structured address.
  ///
  /// Returns `null` when no address can be resolved.
  Future<StructuredAddress?> reverse(double lat, double lon);

  /// Release resources (HTTP clients, caches, etc.).
  void dispose();

  /// Whether this service supports autocomplete-based search.
  ///
  /// When `true`, use [autocomplete] + [placeDetails] instead of [search]
  /// for a richer search-as-you-type UX with a two-step resolution flow.
  bool get supportsAutocomplete => false;

  /// Return search-as-you-type predictions for [input].
  ///
  /// Predictions contain only display text and a [PlacePrediction.placeId];
  /// call [placeDetails] on the selected prediction to obtain full coordinates
  /// and structured address data.
  ///
  /// Returns an empty list by default for services that do not support
  /// autocomplete. Override alongside [supportsAutocomplete] = `true`.
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    String? lang,
    int limit = 5,
  }) async =>
      const [];

  /// Resolve a [placeId] (from a [PlacePrediction]) into a [GeocodingResult]
  /// with full coordinates and structured address components.
  ///
  /// Returns `null` if the place cannot be resolved. Returns `null` by default
  /// for services that do not support autocomplete.
  Future<GeocodingResult?> placeDetails(String placeId) async => null;
}
