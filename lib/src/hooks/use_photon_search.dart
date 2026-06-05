import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';

import '../models/structured_address.dart';
import '../services/photon_service.dart';

/// State returned by [usePhotonSearch].
class PhotonSearchState {
  const PhotonSearchState({
    required this.results,
    required this.isLoading,
    this.error,
  });

  /// Current search results as [StructuredAddress] list.
  final List<StructuredAddress> results;

  /// Whether a search request is in flight.
  final bool isLoading;

  /// Error message if the last search failed.
  final String? error;
}

/// A hook that performs debounced forward geocoding via Photon.
///
/// [query] is the current search text. Results update reactively
/// when [query] changes, debounced by [debounceMs] (default 400ms).
/// In-flight requests are cancelled when a new query arrives.
PhotonSearchState usePhotonSearch(
  String query, {
  List<String>? countryCodes,
  String? lang,
  int debounceMs = 400,
  int limit = 5,
}) {
  final results = useState<List<StructuredAddress>>([]);
  final isLoading = useState(false);
  final error = useState<String?>(null);
  final service = useMemoized(() => PhotonService(), []);

  useEffect(() {
    if (query.trim().isEmpty) {
      results.value = [];
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
        final raw = await service.search(
          query,
          countryCodes: countryCodes,
          lang: lang,
          limit: limit,
        );

        if (cancelled) return;

        results.value =
            raw.map((r) => r.toStructuredAddress()).toList();
        isLoading.value = false;
      } catch (e) {
        if (cancelled) return;
        error.value = 'Search failed. Please try again.';
        isLoading.value = false;
      }
    });

    return () {
      cancelled = true;
      debounceTimer?.cancel();
    };
  }, [query, countryCodes, lang, debounceMs, limit]);

  // Dispose service on unmount.
  useEffect(() => service.dispose, []);

  return PhotonSearchState(
    results: results.value,
    isLoading: isLoading.value,
    error: error.value,
  );
}
