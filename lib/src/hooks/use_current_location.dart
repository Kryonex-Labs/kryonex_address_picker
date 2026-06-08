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

  /// Trigger a one-shot location fetch.
  final Future<void> Function() fetch;
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

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    
    debugPrint('Fetching current location...');

    try {
      // Check if location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        error.value = 'Location services are disabled. '
            'Please enable them in Settings.';
        isLoading.value = false;
        debugPrint('Location services disabled.');
        return;
      }

      // Check and request permission.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('Location permission requested: $permission');
        if (permission == LocationPermission.denied) {
          error.value = 'Location permission denied.';
          isLoading.value = false;
          debugPrint('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        error.value = 'Location permission permanently denied. '
            'Please enable it in Settings.';
        isLoading.value = false;
        debugPrint('Location permission permanently denied.');
        return;
      }

      // Fetch position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      location.value = LatLng(position.latitude, position.longitude);
      isLoading.value = false;
      debugPrint('Current location fetched: ${location.value}');
    } catch (e) {
      error.value = 'Failed to get current location.';
      isLoading.value = false;
      debugPrint('Error fetching location: $e');
    }
  }

  return CurrentLocationState(
    location: location.value,
    isLoading: isLoading.value,
    error: error.value,
    fetch: fetch,
  );
}
