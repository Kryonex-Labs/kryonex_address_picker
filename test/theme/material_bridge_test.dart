import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/theme/material_bridge.dart';

void main() {
  group('bridgeFromMaterial', () {
    test('maps a light Material theme to a light ForUI theme', () {
      final bridged = bridgeFromMaterial(ThemeData(brightness: Brightness.light));
      expect(bridged.colors.brightness, Brightness.light);
    });

    test('maps a dark Material theme to a dark ForUI theme', () {
      final bridged = bridgeFromMaterial(ThemeData(brightness: Brightness.dark));
      expect(bridged.colors.brightness, Brightness.dark);
    });
  });

  group('resolveTheme', () {
    testWidgets('returns the explicit ForUI theme when provided',
        (tester) async {
      final explicit = FThemes.zinc.dark.touch;
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

    testWidgets('bridges the provided Material theme when no ForUI theme',
        (tester) async {
      late FThemeData resolved;

      await tester.pumpWidget(
        MaterialApp(
          // Ambient is light; the explicitly-passed materialTheme is dark and
          // should win over the ambient one.
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              resolved = resolveTheme(
                context,
                materialTheme: ThemeData(brightness: Brightness.dark),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.colors.brightness, Brightness.dark);
    });

    testWidgets('falls back to the ambient Theme when nothing passed',
        (tester) async {
      late FThemeData resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              resolved = resolveTheme(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.colors.brightness, Brightness.dark);
    });
  });
}
