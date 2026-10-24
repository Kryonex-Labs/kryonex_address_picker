import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/theme/material_bridge.dart';

void main() {
  group('bridgeFromMaterial', () {
    test('maps a light Material theme to a light ForUI theme', () {
      final bridged = bridgeFromMaterial(
        ThemeData(brightness: Brightness.light),
      );
      expect(bridged.colors.brightness, Brightness.light);
    });

    test('maps a dark Material theme to a dark ForUI theme', () {
      final bridged = bridgeFromMaterial(
        ThemeData(brightness: Brightness.dark),
      );
      expect(bridged.colors.brightness, Brightness.dark);
    });

    test('maps colorScheme colors to FColors', () {
      const navy = Color(0xFF1B3A63);
      const onNavy = Color(0xFFFFFFFF);
      const secondary = Color(0xFF625B71);
      const onSecondary = Color(0xFFFFFFFF);
      const surface = Color(0xFFF5F5F5);
      const onSurface = Color(0xFF1C1B1F);
      const outline = Color(0xFF79747E);
      const error = Color(0xFFBA1A1A);
      const onError = Color(0xFFFFFFFF);

      final material = ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: navy,
          onPrimary: onNavy,
          secondary: secondary,
          onSecondary: onSecondary,
          surface: surface,
          onSurface: onSurface,
          outline: outline,
          error: error,
          onError: onError,
        ),
      );

      final bridged = bridgeFromMaterial(material);
      final colors = bridged.colors;

      expect(colors.primary, navy);
      expect(colors.primaryForeground, onNavy);
      expect(colors.secondary, secondary);
      expect(colors.secondaryForeground, onSecondary);
      expect(colors.background, surface);
      expect(colors.foreground, onSurface);
      expect(colors.border, outline);
      expect(colors.error, error);
      expect(colors.errorForeground, onError);
      expect(colors.destructive, error);
      expect(colors.destructiveForeground, onError);
    });

    test('preserves base font family', () {
      final base = FTheme.neutral.light.touch;
      final bridged = bridgeFromMaterial(
        ThemeData(brightness: Brightness.light),
      );
      expect(
        bridged.typography.body.fontFamily,
        base.typography.body.fontFamily,
      );
    });
  });

  group('resolveTheme', () {
    testWidgets('returns the explicit ForUI theme when provided', (
      tester,
    ) async {
      final explicit = FTheme.neutral.dark.touch;
      late FThemeData resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              resolved = resolveTheme(context, forUiTheme: explicit);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(resolved, explicit), isTrue);
    });

    testWidgets('bridges the provided Material theme when no ForUI theme', (
      tester,
    ) async {
      late FThemeData resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              resolved = resolveTheme(
                context,
                materialTheme: ThemeData(
                  brightness: Brightness.dark,
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFFBB86FC),
                  ),
                ),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.colors.brightness, Brightness.dark);
      expect(resolved.colors.primary, const Color(0xFFBB86FC));
    });

    testWidgets('falls back to the ambient Theme when nothing passed', (
      tester,
    ) async {
      late FThemeData resolved;
      const ambientPrimary = Color(0xFF6750A4);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(primary: ambientPrimary),
          ),
          home: Builder(
            builder: (context) {
              resolved = resolveTheme(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.colors.brightness, Brightness.light);
      expect(resolved.colors.primary, ambientPrimary);
    });
  });
}
