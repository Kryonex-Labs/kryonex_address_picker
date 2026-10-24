import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Bridges a Material [ThemeData] into a ForUI [FThemeData].
///
/// Maps [ColorScheme] colors onto the ForUI [FColors] equivalents so
/// host apps get consistent theming without an explicit [FThemeData].
///
/// Mapped colors:
/// - `colorScheme.primary` → `FColors.primary`
/// - `colorScheme.onPrimary` → `FColors.primaryForeground`
/// - `colorScheme.secondary` → `FColors.secondary`
/// - `colorScheme.onSecondary` → `FColors.secondaryForeground`
/// - `colorScheme.surface` → `FColors.background`
/// - `colorScheme.onSurface` → `FColors.foreground`
/// - `colorScheme.outline` → `FColors.border`
/// - `colorScheme.surfaceContainerHighest` → `FColors.muted`
/// - `colorScheme.onSurfaceVariant` → `FColors.mutedForeground`
/// - `colorScheme.error` → `FColors.error` / `FColors.destructive`
/// - `colorScheme.onError` → `FColors.errorForeground` / `FColors.destructiveForeground`
/// - `colorScheme.surfaceContainerLow` → `FColors.card`
///
FThemeData bridgeFromMaterial(ThemeData material) {
  final base = material.brightness == Brightness.dark
      ? FThemes.neutral.dark.touch
      : FThemes.neutral.light.touch;

  final cs = material.colorScheme;

  // ponytail: FThemeData(colors:, touch:) recomputes all widget styles from
  // the bridged colors — no need to copy individual component styles.
  return FThemeData(
    colors: base.colors.copyWith(
      primary: cs.primary,
      primaryForeground: cs.onPrimary,
      secondary: cs.secondary,
      secondaryForeground: cs.onSecondary,
      background: cs.surface,
      foreground: cs.onSurface,
      border: cs.outline,
      muted: cs.surfaceContainerHighest,
      mutedForeground: cs.onSurfaceVariant,
      destructive: cs.error,
      destructiveForeground: cs.onError,
      error: cs.error,
      errorForeground: cs.onError,
      card: cs.surfaceContainerLow,
    ),
    touch: true,
  );
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
