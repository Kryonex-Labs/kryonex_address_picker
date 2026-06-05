import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latlong2/latlong.dart';

import '../models/structured_address.dart';
import '../services/photon_service.dart';

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
ReverseGeocodeState useReverseGeocode(LatLng? latLng) {
  final address = useState<StructuredAddress?>(null);
  final isLoading = useState(false);
  final error = useState<String?>(null);
  final service = useMemoized(() => PhotonService(), []);

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
      } catch (e) {
        if (cancelled) return;
        error.value = 'Reverse geocoding failed.';
        isLoading.value = false;
      }
    }();

    return () {
      cancelled = true;
    };
  }, [latLng]);

  // Dispose service on unmount.
  useEffect(() => service.dispose, []);

  return ReverseGeocodeState(
    address: address.value,
    isLoading: isLoading.value,
    error: error.value,
  );
}
