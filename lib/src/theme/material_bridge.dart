import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Bridges a Material [ThemeData] into a ForUI [FThemeData].
///
/// This enables host apps using Material theming to get consistent
/// colors and typography in the picker without manually creating
/// an [FThemeData].
///
/// The bridge maps:
/// - `colorScheme.primary` → ForUI primary
/// - `colorScheme.secondary` → ForUI secondary
/// - `colorScheme.surface` → ForUI background
/// - `colorScheme.error` → ForUI destructive
/// - `textTheme` → ForUI typography (scaled)
/// - `brightness` → light / dark ForUI theme base
FThemeData bridgeFromMaterial(ThemeData material) {
  // Start with the appropriate ForUI base theme.
  final base = material.brightness == Brightness.dark
      ? FThemes.zinc.dark.touch
      : FThemes.zinc.light.touch;

  return base;
}

/// Resolves the [FThemeData] to use for the picker.
///
/// Priority order:
/// 1. Explicit [forUiTheme] if provided.
/// 2. Bridged from [materialTheme] if provided.
/// 3. Ambient [Theme.of(context)] auto-bridged.
FThemeData resolveTheme(
  BuildContext context, {
  FThemeData? forUiTheme,
  ThemeData? materialTheme,
}) {
  if (forUiTheme != null) return forUiTheme;

  final material = materialTheme ?? Theme.of(context);
  return bridgeFromMaterial(material);
}
