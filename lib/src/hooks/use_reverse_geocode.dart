import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latlong2/latlong.dart';

import '../models/structured_address.dart';
import '../services/geocoding_service.dart';

/// State returned by [useReverseGeocode].
class ReverseGeocodeState {
  const ReverseGeocodeState({
    this.address,
    required this.isLoading,
    this.error,
  });

  /// The resolved address, or null if not yet resolved.
  final StructuredAddress? address;

  /// Whether a reverse geocode request is in flight.
  final bool isLoading;

  /// Error message if the last lookup failed.
  final String? error;
}

/// A hook that reverse-geocodes a [LatLng] into a [StructuredAddress].
///
/// Fires automatically when [latLng] changes. Returns loading state
/// while the request is in-flight. Cancels prior requests when
/// coordinates change.
///
/// The caller is responsible for the lifecycle of [service] — this hook
/// does **not** call [GeocodingService.dispose].
ReverseGeocodeState useReverseGeocode(
  LatLng? latLng, {
  required GeocodingService service,
}) {
  final address = useState<StructuredAddress?>(null);
  final isLoading = useState(false);
  final error = useState<String?>(null);

  useEffect(() {
    if (latLng == null) {
      address.value = null;
      isLoading.value = false;
      error.value = null;
      return null;
    }

    isLoading.value = true;
    error.value = null;
    var cancelled = false;

    () async {
      try {
        final result = await service.reverse(
          latLng.latitude,
          latLng.longitude,
        );

        if (cancelled) return;

        address.value = result;
        isLoading.value = false;

        if (result == null) {
          error.value = 'Could not resolve address at this location.';
        }
      } catch (e, trace) {
        if (cancelled) return;
        debugPrint('[AddressPicker] useReverseGeocode error: $e\n$trace');
        error.value = 'Reverse geocoding failed.';
        isLoading.value = false;
      }
    }();

    return () {
      cancelled = true;
    };
  }, [latLng]);

  return ReverseGeocodeState(
    address: address.value,
    isLoading: isLoading.value,
    error: error.value,
  );
}
