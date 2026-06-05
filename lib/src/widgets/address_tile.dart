import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/structured_address.dart';

/// An [FTile] displaying a geocoding search result.
///
/// Shows a location icon prefix, primary address line as title,
/// and city/state/zip as subtitle.
class AddressTile extends StatelessWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.onTap,
  });

  /// The address to display.
  final StructuredAddress address;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FTile(
      prefix: const Icon(Icons.location_on_outlined, size: 20),
      title: Text(
        address.primaryLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        address.secondaryLine,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPress: onTap,
    );
  }
}
