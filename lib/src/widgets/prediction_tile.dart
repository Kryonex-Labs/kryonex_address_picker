import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/place_prediction.dart';

/// An [FTile] displaying a Places API autocomplete prediction.
///
/// Shows a spinner prefix while [isLoading] is `true` (place details are being
/// fetched), or a location icon when idle. Interaction is blocked during
/// loading to prevent double-taps.
class PredictionTile extends StatelessWidget {
  const PredictionTile({
    super.key,
    required this.prediction,
    required this.onTap,
    this.isLoading = false,
  });

  /// The autocomplete prediction to display.
  final PlacePrediction prediction;

  /// Called when the tile is tapped (while not loading).
  final VoidCallback onTap;

  /// When `true`, shows a spinner and disables the tap handler.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTile(
      prefix: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            )
          : const Icon(Icons.location_on_outlined, size: 20),
      title: Text(
        prediction.mainText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: prediction.secondaryText.isNotEmpty
          ? Text(
              prediction.secondaryText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onPress: isLoading ? null : onTap,
    );
  }
}
