import 'package:flutter/material.dart';

import 'models/address_details.dart';
import 'models/selected_address.dart';
import 'models/structured_address.dart';
import 'screens/address_detail_screen.dart';
import 'screens/map_confirm_screen.dart';
import 'screens/search_screen.dart';
import 'theme/picker_theme.dart';

/// Shows the address picker as a full-screen page.
///
/// Returns a [SelectedAddress] if the user completes the flow, or
/// `null` if they dismiss the picker at any point.
///
/// ```dart
/// final result = await showAddressPicker(context);
/// if (result != null) {
///   print(result.address.displayName);
///   print(result.details?.apt);
/// }
/// ```
Future<SelectedAddress?> showAddressPicker(
  BuildContext context, {
  AddressPickerConfig? config,
}) {
  final effectiveConfig = config ?? const AddressPickerConfig();

  return Navigator.of(context).push<SelectedAddress>(
    MaterialPageRoute(
      builder: (_) => _AddressPickerFlow(config: effectiveConfig),
    ),
  );
}

/// Internal widget that orchestrates the multi-screen picker flow.
class _AddressPickerFlow extends StatefulWidget {
  const _AddressPickerFlow({required this.config});

  final AddressPickerConfig config;

  @override
  State<_AddressPickerFlow> createState() => _AddressPickerFlowState();
}

class _AddressPickerFlowState extends State<_AddressPickerFlow> {
  void _onAddressSelected(StructuredAddress address) {
    // Navigate to map confirmation.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapConfirmScreen(
          config: widget.config,
          initialAddress: address,
          onConfirm: _onMapConfirmed,
        ),
      ),
    );
  }

  void _onPickOnMap() {
    // Navigate to map confirmation without an initial address.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapConfirmScreen(
          config: widget.config,
          initialAddress: null,
          onConfirm: _onMapConfirmed,
        ),
      ),
    );
  }

  Future<void> _onMapConfirmed(StructuredAddress address) async {
    if (!widget.config.showDetailScreen) {
      // Skip detail step — return immediately.
      _returnResult(address, null);
      return;
    }

    // Present the detail sheet as a frosted-glass modal over the map.
    final details = await showAddressDetailSheet(
      context,
      config: widget.config,
      address: address,
      fields: widget.config.effectiveDetailFields,
    );

    if (!mounted) return;

    if (details != null) {
      _returnResult(address, details);
    }
    // A null result means the sheet was dismissed; the user stays on the map
    // to re-confirm or pick a different location.
  }

  void _returnResult(StructuredAddress address, AddressDetails? details) {
    final result = SelectedAddress(address: address, details: details);

    final navigator = Navigator.of(context);
    final flowRoute = ModalRoute.of(context);

    // Pop the intermediate screens (map confirm, detail) stacked above the
    // picker flow, then pop the flow route itself with the result so it is
    // delivered to the `showAddressPicker` caller.
    navigator.popUntil((route) => route == flowRoute);
    navigator.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return SearchScreen(
      config: widget.config,
      onAddressSelected: _onAddressSelected,
      onPickOnMap: _onPickOnMap,
      onCurrentLocation: _onAddressSelected,
    );
  }
}
