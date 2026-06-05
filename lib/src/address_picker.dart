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
  StructuredAddress? _confirmedAddress;

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

  void _onMapConfirmed(StructuredAddress address) {
    _confirmedAddress = address;

    if (widget.config.showDetailScreen) {
      // Navigate to detail screen.
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddressDetailScreen(
            config: widget.config,
            address: address,
            detailFields: widget.config.effectiveDetailFields,
            onSave: _onDetailsSaved,
          ),
        ),
      );
    } else {
      // Skip detail screen — return immediately.
      _returnResult(address, null);
    }
  }

  void _onDetailsSaved(AddressDetails details) {
    if (_confirmedAddress != null) {
      _returnResult(_confirmedAddress!, details);
    }
  }

  void _returnResult(StructuredAddress address, AddressDetails? details) {
    final result = SelectedAddress(address: address, details: details);

    // Pop all the way back to the caller.
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).pop(result);
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
