import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/widgets/address_tile.dart';

import '../_support/fixtures.dart';
import '../_support/test_app.dart';

void main() {
  group('AddressTile', () {
    testWidgets('renders the address lines and a location icon',
        (tester) async {
      final address = buildAddress();
      await tester.pumpWidget(
        wrapForTest(AddressTile(address: address, onTap: () {})),
      );

      expect(find.text(address.primaryLine), findsOneWidget);
      expect(find.text(address.secondaryLine), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('fires onTap when pressed', (tester) async {
      var tapped = false;
      final address = buildAddress();
      await tester.pumpWidget(
        wrapForTest(AddressTile(address: address, onTap: () => tapped = true)),
      );

      await tester.tap(find.text(address.primaryLine));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
