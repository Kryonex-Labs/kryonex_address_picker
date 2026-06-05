import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../hooks/use_map_controller.dart';
import '../hooks/use_reverse_geocode.dart';
import '../models/structured_address.dart';
import '../theme/material_bridge.dart';
import '../theme/picker_theme.dart';
import '../widgets/address_card.dart';
import '../widgets/map_pin.dart';

/// Map confirmation screen.
///
/// Shows a map with a pin at the selected location. The user can tap
/// anywhere on the map to move the pin. The resolved address is shown
/// in a card overlay at the bottom.
class MapConfirmScreen extends HookWidget {
  const MapConfirmScreen({
    super.key,
    required this.config,
    required this.initialAddress,
    required this.onConfirm,
  });

  /// Picker configuration.
  final AddressPickerConfig config;

  /// The address to center on initially. Can be null for "Pick on Map" flow.
  final StructuredAddress? initialAddress;

  /// Called when the user confirms the address.
  final ValueChanged<StructuredAddress> onConfirm;

  @override
  Widget build(BuildContext context) {
    final mapController = useMapController();
    final selectedLatLng = useState<LatLng?>(initialAddress?.latLng);
    final reverseState = useReverseGeocode(selectedLatLng.value);

    // Use the reverse-geocoded address when available, fall back to initial.
    final displayAddress = reverseState.address ?? initialAddress;

    final initialCenter = initialAddress?.latLng ??
        config.initialLocation ??
        const LatLng(37.7749, -122.4194); // Default: San Francisco

    final theme = resolveTheme(
      context,
      forUiTheme: config.theme,
      materialTheme: config.materialTheme,
    );

    return FTheme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirm Location'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back to search',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: config.mapZoom,
                onTap: (tapPosition, latLng) {
                  selectedLatLng.value = latLng;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kryonex.address_picker',
                ),
                if (selectedLatLng.value != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLatLng.value!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const MapPin(),
                      ),
                    ],
                  ),
              ],
            ),

            // Re-center button
            Positioned(
              right: 16,
              bottom: 200,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                onPressed: () {
                  final center =
                      selectedLatLng.value ?? initialCenter;
                  mapController.move(center, config.mapZoom);
                },
                child: const Icon(Icons.my_location),
              ),
            ),

            // Address card overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AddressCard(
                    address: displayAddress,
                    isLoading: reverseState.isLoading,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: displayAddress != null &&
                              !reverseState.isLoading
                          ? () => onConfirm(displayAddress)
                          : null,
                      child: const Text('Confirm Address'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
