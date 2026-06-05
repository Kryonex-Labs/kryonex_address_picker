import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/widgets/recent_address_tile.dart';

import '../_support/fixtures.dart';
import '../_support/test_app.dart';

void main() {
  group('RecentAddressTile', () {
    testWidgets('renders the address lines and a clock icon', (tester) async {
      final address = buildAddress();
      await tester.pumpWidget(
        wrapForTest(RecentAddressTile(address: address, onTap: () {})),
      );

      expect(find.text(address.primaryLine), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('fires onTap when pressed', (tester) async {
      var tapped = false;
      final address = buildAddress();
      await tester.pumpWidget(
        wrapForTest(
          RecentAddressTile(address: address, onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text(address.primaryLine));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
