import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:kryonex_address_picker/src/screens/map_confirm_screen.dart';
import 'package:kryonex_address_picker/src/widgets/map_pin.dart';

import '../_support/fixtures.dart';

/// Wraps [MapConfirmScreen] in a minimal [MaterialApp].
Widget buildMapScreen({
  required StructuredAddress? initialAddress,
  required ValueChanged<StructuredAddress> onConfirm,
  AddressPickerConfig config = const AddressPickerConfig(),
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    home: MapConfirmScreen(
      config: config,
      initialAddress: initialAddress,
      onConfirm: onConfirm,
    ),
  );
}

/// Drain any ForUI tappable animation timers (100ms) after a gesture.
Future<void> drainForUiTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('MapConfirmScreen', () {
    testWidgets('displays "Confirm Location" app bar title', (tester) async {
      await tester.pumpWidget(
        buildMapScreen(initialAddress: buildAddress(), onConfirm: (_) {}),
      );
      await tester.pump();

      expect(find.text('Confirm Location'), findsOneWidget);
      await drainForUiTimers(tester);
    });

    testWidgets('shows address primary line from initialAddress immediately',
        (tester) async {
      final address = buildAddress();
      await tester.pumpWidget(
        buildMapScreen(initialAddress: address, onConfirm: (_) {}),
      );
      await tester.pump();

      expect(find.text(address.primaryLine), findsOneWidget);
      await drainForUiTimers(tester);
    });

    testWidgets(
        'Confirm button is enabled when initialAddress is set and not loading',
        (tester) async {
      final address = buildAddress();
      StructuredAddress? confirmed;

      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: address,
          onConfirm: (a) => confirmed = a,
        ),
      );
      await tester.pump();

      final confirmButton = find.text('Confirm Address');
      expect(confirmButton, findsOneWidget);

      await tester.tap(confirmButton);
      await drainForUiTimers(tester);

      expect(confirmed, isNotNull);
    });

    testWidgets('shows placeholder text when no initialAddress provided',
        (tester) async {
      await tester.pumpWidget(
        buildMapScreen(initialAddress: null, onConfirm: (_) {}),
      );
      await tester.pump();

      expect(find.text('Tap on the map to select a location'), findsOneWidget);
      await drainForUiTimers(tester);
    });

    testWidgets('Confirm button is disabled (onPress null) when no address set',
        (tester) async {
      await tester.pumpWidget(
        buildMapScreen(initialAddress: null, onConfirm: (_) {}),
      );
      await tester.pump();

      // Check that the Confirm FilledButton has null onPressed.
      final disabledButtons = find.byWidgetPredicate(
        (w) => w is FilledButton && w.onPressed == null,
      );
      expect(disabledButtons, findsWidgets);
      await drainForUiTimers(tester);
    });
  });

  group('MapConfirmScreen — new theming options', () {
    testWidgets('pinBuilder override is rendered instead of default MapPin',
        (tester) async {
      const pinKey = Key('custom-pin');
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
          config: AddressPickerConfig(
            pinBuilder: (_) => const SizedBox(key: pinKey, width: 40, height: 40),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(pinKey), findsOneWidget);
      expect(find.byType(MapPin), findsNothing);
      await drainForUiTimers(tester);
    });

    testWidgets('confirmButtonStyle is applied to Confirm button',
        (tester) async {
      final customStyle = FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFF5733),
      );
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
          config: AddressPickerConfig(confirmButtonStyle: customStyle),
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirm Address'),
      );
      expect(button.style, customStyle);
      await drainForUiTimers(tester);
    });

    testWidgets('mapDarkMode.dark wraps tiles in a ColorFiltered widget',
        (tester) async {
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
          config: const AddressPickerConfig(mapDarkMode: MapDarkMode.dark),
        ),
      );
      await tester.pump();

      // The tileBuilder wraps each tile in ColorFiltered.
      expect(find.byType(ColorFiltered), findsWidgets);
      await drainForUiTimers(tester);
    });

    testWidgets('mapDarkMode.light does not apply ColorFiltered on light theme',
        (tester) async {
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
          config: const AddressPickerConfig(mapDarkMode: MapDarkMode.light),
          theme: ThemeData(brightness: Brightness.light),
        ),
      );
      await tester.pump();

      // No ColorFiltered overlay should be present.
      expect(find.byType(ColorFiltered), findsNothing);
      await drainForUiTimers(tester);
    });

    testWidgets('attribution text is shown by default (OSM attribution)',
        (tester) async {
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
        ),
      );
      await tester.pump();

      expect(
        find.text('© OpenStreetMap contributors'),
        findsOneWidget,
      );
      await drainForUiTimers(tester);
    });

    testWidgets('attributionStyle: null suppresses the attribution widget',
        (tester) async {
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
          config: const AddressPickerConfig(attributionStyle: null),
        ),
      );
      await tester.pump();

      expect(
        find.byType(SimpleAttributionWidget),
        findsNothing,
      );
      await drainForUiTimers(tester);
    });

    testWidgets('custom attribution text is rendered', (tester) async {
      const customAttribution = AddressPickerAttribution(
        text: 'Custom Map Data',
      );
      await tester.pumpWidget(
        buildMapScreen(
          initialAddress: buildAddress(),
          onConfirm: (_) {},
          config: const AddressPickerConfig(attributionStyle: customAttribution),
        ),
      );
      await tester.pump();

      expect(find.text('Custom Map Data'), findsOneWidget);
      await drainForUiTimers(tester);
    });
  });
}
