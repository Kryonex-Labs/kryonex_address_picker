import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/hooks/use_recent_addresses.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../_support/fixtures.dart';

void main() {
  group('useRecentAddresses', () {
    RecentAddressesState? captured;

    Widget buildHarness({int maxAddresses = 5}) {
      return MaterialApp(
        home: HookBuilder(
          builder: (context) {
            captured = useRecentAddresses(maxAddresses: maxAddresses);
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () => captured!.save(buildAddress()),
                  child: const Text('save'),
                ),
                ElevatedButton(
                  onPressed: () => captured!.clear(),
                  child: const Text('clear'),
                ),
                Text('count:${captured!.addresses.length}'),
              ],
            );
          },
        ),
      );
    }

    testWidgets('save adds address and refreshes list', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(captured!.addresses, isEmpty);

      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();

      expect(captured!.addresses, hasLength(1));
      expect(
        captured!.addresses.first.displayName,
        buildAddress().displayName,
      );
    });

    testWidgets('clear removes all addresses', (tester) async {
      final seeded = [buildAddress().toJson()];
      SharedPreferences.setMockInitialValues({
        'kryonex_recent_addresses': json.encode(seeded),
      });

      await tester.pumpWidget(buildHarness());
      await tester.pumpAndSettle();

      expect(captured!.addresses, hasLength(1));

      await tester.tap(find.text('clear'));
      await tester.pumpAndSettle();

      expect(captured!.addresses, isEmpty);
    });
  });
}
