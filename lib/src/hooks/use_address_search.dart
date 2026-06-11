import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../models/place_prediction.dart';
import '../models/structured_address.dart';
import '../services/geocoding_service.dart';

/// State returned by [useAddressSearch].
class AddressSearchState {
  const AddressSearchState({
    required this.results,
    required this.predictions,
    required this.isLoading,
    this.error,
  });

  /// Current search results as [StructuredAddress] list.
  ///
  /// Populated when [service] does **not** support autocomplete
  /// (i.e. [GeocodingService.supportsAutocomplete] is `false`).
  final List<StructuredAddress> results;

  /// Current autocomplete predictions.
  ///
  /// Populated when [service] supports autocomplete
  /// (i.e. [GeocodingService.supportsAutocomplete] is `true`).
  /// Each prediction must be resolved via [GeocodingService.placeDetails]
  /// before coordinates are available.
  final List<PlacePrediction> predictions;

  /// Whether a search request is in flight.
  final bool isLoading;

  /// Error message if the last search failed.
  final String? error;
}

/// A hook that performs debounced forward geocoding via [service].
///
/// [query] is the current search text. Results update reactively when
/// [query] changes, debounced by [debounceMs] (default 400ms).
/// In-flight requests are cancelled when a new query arrives.
///
/// When [service] supports autocomplete ([GeocodingService.supportsAutocomplete]
/// is `true`), the hook calls [GeocodingService.autocomplete] and populates
/// [AddressSearchState.predictions]. Otherwise it falls back to
/// [GeocodingService.search] and populates [AddressSearchState.results].
///
/// The caller is responsible for the lifecycle of [service] — this hook
/// does **not** call [GeocodingService.dispose].
AddressSearchState useAddressSearch(
  String query, {
  required GeocodingService service,
  List<String>? countryCodes,
  String? lang,
  int debounceMs = 400,
  int limit = 5,
}) {
  final results = useState<List<StructuredAddress>>([]);
  final predictions = useState<List<PlacePrediction>>([]);
  final isLoading = useState(false);
  final error = useState<String?>(null);

  useEffect(() {
    if (query.trim().isEmpty) {
      results.value = [];
      predictions.value = [];
      isLoading.value = false;
      error.value = null;
      return null;
    }

    isLoading.value = true;
    error.value = null;

    Timer? debounceTimer;
    var cancelled = false;

    debounceTimer = Timer(Duration(milliseconds: debounceMs), () async {
      if (cancelled) return;

      try {
        if (service.supportsAutocomplete) {
          final preds = await service.autocomplete(
            query,
            lang: lang,
            limit: limit,
          );
          if (cancelled) return;
          predictions.value = preds;
          results.value = [];
        } else {
          final raw = await service.search(
            query,
            countryCodes: countryCodes,
            lang: lang,
            limit: limit,
          );
          if (cancelled) return;
          results.value = raw.map((r) => r.toStructuredAddress()).toList();
          predictions.value = [];
        }
        isLoading.value = false;
      } catch (e, trace) {
        if (cancelled) return;
        debugPrint('[AddressPicker] useAddressSearch error: $e\n$trace');
        error.value = 'Search failed. Please try again.';
        isLoading.value = false;
      }
    });

    return () {
      cancelled = true;
      debounceTimer?.cancel();
    };
  }, [query, countryCodes, lang, debounceMs, limit]);

  return AddressSearchState(
    results: results.value,
    predictions: predictions.value,
    isLoading: isLoading.value,
    error: error.value,
  );
}
