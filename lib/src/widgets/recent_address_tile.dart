import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/structured_address.dart';

/// An [FTile] displaying a recently selected address.
///
/// Shows a clock icon prefix, primary line as title, and
/// secondary line as subtitle.
class RecentAddressTile extends StatelessWidget {
  const RecentAddressTile({
    super.key,
    required this.address,
    required this.onTap,
  });

  /// The recent address to display.
  final StructuredAddress address;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FTile(
      prefix: const Icon(Icons.access_time, size: 20),
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
