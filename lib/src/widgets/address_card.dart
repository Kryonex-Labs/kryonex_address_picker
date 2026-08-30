import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/structured_address.dart';

/// An [FCard] displaying a parsed address with title and subtitle.
///
/// Used on the map confirmation screen as an overlay showing the
/// currently selected address.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.isLoading = false,
  });

  /// The address to display.
  final StructuredAddress? address;

  /// Whether the address is still being resolved (reverse geocoding).
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const FCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (address == null) {
      return FCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Tap on the map to select a location',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return FCard(
      child: FTile(
        prefix: const Icon(Icons.location_on_outlined, size: 20),
        title: Text(
          address!.primaryLine,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          address!.secondaryLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
