import 'package:flutter/material.dart';

/// Custom map pin marker for the confirmation screen.
///
/// A simple drop-pin icon rendered as a Flutter widget so it can
/// be used with [flutter_map]'s [Marker] widget builder.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    this.size = 40.0,
    this.color,
  });

  /// The size of the pin icon.
  final double size;

  /// Pin color. Defaults to the theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final pinColor = color ?? Theme.of(context).colorScheme.primary;

    return Icon(
      Icons.location_pin,
      size: size,
      color: pinColor,
      semanticLabel: 'Selected location pin',
    );
  }
}
