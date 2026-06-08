import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// State returned by [useCurrentLocation].
class CurrentLocationState {
  const CurrentLocationState({
    this.location,
    required this.isLoading,
    this.error,
    required this.fetch,
  });

  /// The device's current location, or null if not yet resolved.
  final LatLng? location;

  /// Whether a location request is in progress.
  final bool isLoading;

  /// Human-readable error message if location fetch failed.
  final String? error;

  /// Trigger a one-shot location fetch. Returns the resolved location and
  /// error directly so callers can react without waiting for a rebuild
  /// (the snapshot they captured at build time is stale by the time the
  /// future completes).
  final Future<({LatLng? location, String? error})> Function() fetch;
}

/// A hook that provides one-shot current location via [Geolocator].
///
/// Does **not** auto-fetch on mount — call [CurrentLocationState.fetch]
/// explicitly when the user taps "Use current location".
///
/// Handles permission checks and provides clear error messages for
/// each failure mode (service disabled, permission denied, etc.).
CurrentLocationState useCurrentLocation() {
  final location = useState<LatLng?>(null);
  final isLoading = useState(false);
  final error = useState<String?>(null);

  Future<({LatLng? location, String? error})> fetch() async {
    isLoading.value = true;
    error.value = null;

    debugPrint('Fetching current location...');

    String? fail(String message) {
      error.value = message;
      isLoading.value = false;
      return message;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled.');
        return (
          location: null,
          error: fail('Location services are disabled. '
              'Please enable them in Settings.'),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Location permission requested: $permission');
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          return (location: null, error: fail('Location permission denied.'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied.');
        return (
          location: null,
          error: fail('Location permission permanently denied. '
              'Please enable it in Settings.'),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final resolved = LatLng(position.latitude, position.longitude);
      location.value = resolved;
      isLoading.value = false;
      debugPrint('Current location fetched: $resolved');
      return (location: resolved, error: null);
    } catch (e) {
      debugPrint('Error fetching location: $e');
      return (
        location: null,
        error: fail('Failed to get current location.'),
      );
    }
  }

  return CurrentLocationState(
    location: location.value,
    isLoading: isLoading.value,
    error: error.value,
    fetch: fetch,
  );
}
