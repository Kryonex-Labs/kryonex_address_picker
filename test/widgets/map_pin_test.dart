import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/widgets/map_pin.dart';

import '../_support/test_app.dart';

void main() {
  group('MapPin', () {
    testWidgets('renders the location_pin icon at the default size',
        (tester) async {
      await tester.pumpWidget(wrapForTest(const MapPin()));

      final icon = tester.widget<Icon>(find.byIcon(Icons.location_pin));
      expect(icon.size, 40.0);
    });

    testWidgets('default color resolves from colorScheme.primary', (tester) async {
      final theme = ThemeData(colorSchemeSeed: Colors.blue);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: MapPin()),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.location_pin));
      expect(icon.color, theme.colorScheme.primary);
    });

    testWidgets('honors explicit size and color', (tester) async {
      await tester.pumpWidget(
        wrapForTest(const MapPin(size: 64, color: Colors.red)),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.location_pin));
      expect(icon.size, 64);
      expect(icon.color, Colors.red);
    });
  });
}
