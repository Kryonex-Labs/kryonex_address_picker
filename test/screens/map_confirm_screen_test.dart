import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:kryonex_address_picker/src/screens/map_confirm_screen.dart';

import '../_support/fixtures.dart';

/// Wraps [MapConfirmScreen] in a minimal [MaterialApp].
Widget buildMapScreen({
  required StructuredAddress? initialAddress,
  required ValueChanged<StructuredAddress> onConfirm,
}) {
  return MaterialApp(
    home: MapConfirmScreen(
      config: const AddressPickerConfig(),
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

      // Check that at least one FButton has null onPress (the Confirm button).
      final disabledButtons = find.byWidgetPredicate(
        (w) => w is FButton && w.onPress == null,
      );
      expect(disabledButtons, findsWidgets);
      await drainForUiTimers(tester);
    });
  });
}
