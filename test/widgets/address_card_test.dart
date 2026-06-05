import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/widgets/address_card.dart';

import '../_support/fixtures.dart';
import '../_support/test_app.dart';

void main() {
  group('AddressCard', () {
    testWidgets('renders primary and secondary lines for an address',
        (tester) async {
      final address = buildAddress();
      await tester.pumpWidget(wrapForTest(AddressCard(address: address)));

      expect(find.text(address.primaryLine), findsOneWidget);
      expect(find.text(address.secondaryLine), findsOneWidget);
    });

    testWidgets('shows a spinner when loading', (tester) async {
      await tester.pumpWidget(
        wrapForTest(AddressCard(address: buildAddress(), isLoading: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows placeholder when address is null and not loading',
        (tester) async {
      await tester.pumpWidget(
        wrapForTest(const AddressCard(address: null)),
      );

      expect(find.text('Tap on the map to select a location'), findsOneWidget);
    });
  });
}
