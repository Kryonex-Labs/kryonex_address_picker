import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../_support/fake_geolocator.dart';
import '../_support/fixtures.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Host widget that opens the picker and exposes the result.
// ─────────────────────────────────────────────────────────────────────────────

class _Host extends StatefulWidget {
  const _Host({required this.config});
  final AddressPickerConfig config;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  SelectedAddress? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final r = await showAddressPicker(context, config: widget.config);
              if (mounted) setState(() => result = r);
            },
            child: const Text('open'),
          ),
          if (result != null)
            Text('result:${result!.address.displayName}'),
        ],
      ),
    );
  }
}

Widget buildHost({AddressPickerConfig config = const AddressPickerConfig()}) {
  return MaterialApp(home: _Host(config: config));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pumps enough frames to drain ForUI tappable timers (100ms) and complete a
/// navigation transition (~300ms total). Works even when flutter_map tiles are
/// loading because we advance fake time rather than wait for settle.
Future<void> advance(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 75));
  }
}

/// Opens the picker by tapping the Material ElevatedButton on the host.
Future<void> openPicker(WidgetTester t) async {
  await t.tap(find.text('open'));
  await t.pumpAndSettle(); // no ForUI/map on host
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installGeolocatorMock();
  });

  group('showAddressPicker flow', () {
    // ── dismissal ─────────────────────────────────────────────────────────────
    testWidgets('dismissal returns null: back from SearchScreen',
        (tester) async {
      await tester.pumpWidget(
        buildHost(
          config: const AddressPickerConfig(localeAwareSearch: false),
        ),
      );

      await openPicker(tester);

      // SearchScreen is shown.
      expect(find.text('Search Address'), findsOneWidget);

      // Tap the back arrow.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back on host with no result.
      expect(find.text('open'), findsOneWidget);
      expect(find.textContaining('result:'), findsNothing);
    });

    // ── "Pick on Map" path ────────────────────────────────────────────────────
    testWidgets('"Pick on Map" navigates to MapConfirmScreen without address',
        (tester) async {
      await tester.pumpWidget(
        buildHost(
          config: const AddressPickerConfig(localeAwareSearch: false),
        ),
      );

      await openPicker(tester);
      expect(find.text('Search Address'), findsOneWidget);

      await tester.tap(find.text('Pick on Map'));
      await advance(tester); // drain ForUI timer + navigation animation

      expect(find.text('Confirm Location'), findsOneWidget);
      expect(
        find.text('Tap on the map to select a location'),
        findsOneWidget,
      );

      // Drain any remaining flutter_map timers.
      await advance(tester);
    });

    // ── select from recents + map confirm (no detail screen) ─────────────────
    testWidgets(
        'select recent → map confirm → returns SelectedAddress (no details)',
        (tester) async {
      final address = buildAddress(displayName: 'Saved Place');
      SharedPreferences.setMockInitialValues({
        'kryonex_recent_addresses': json.encode([address.toJson()]),
      });

      await tester.pumpWidget(
        buildHost(
          config: const AddressPickerConfig(
            showDetailScreen: false,
            localeAwareSearch: false,
          ),
        ),
      );

      // Open → SearchScreen.
      await openPicker(tester);
      await tester.pump(); // load recents

      // Wait for recents to load from SharedPreferences.
      await advance(tester);

      // Tap the recent address tile.
      expect(find.text(address.primaryLine), findsOneWidget);
      await tester.tap(find.text(address.primaryLine));
      await advance(tester); // drain ForUI timer + navigate to MapConfirmScreen

      expect(find.text('Confirm Location'), findsOneWidget);

      // Tap confirm.
      await tester.tap(find.text('Confirm Address'));
      await advance(tester); // drain ForUI timer + async _onMapConfirmed

      // showDetailScreen=false → result returned immediately.
      await advance(tester); // ensure host state updates
      expect(find.text('result:${address.displayName}'), findsOneWidget);
    });

    // ── select from recents + map confirm + detail sheet ─────────────────────
    testWidgets(
        'select recent → map confirm → detail sheet → save → returns result',
        (tester) async {
      final address = buildAddress(displayName: 'Place With Details');
      SharedPreferences.setMockInitialValues({
        'kryonex_recent_addresses': json.encode([address.toJson()]),
      });

      await tester.pumpWidget(
        buildHost(
          config: const AddressPickerConfig(
            showDetailScreen: true,
            localeAwareSearch: false,
          ),
        ),
      );

      await openPicker(tester);
      await advance(tester); // load recents

      await tester.tap(find.text(address.primaryLine));
      await advance(tester); // navigate to MapConfirmScreen

      expect(find.text('Confirm Location'), findsOneWidget);

      await tester.tap(find.text('Confirm Address'));
      await advance(tester); // _onMapConfirmed fires sheet

      // Detail sheet slides up.
      expect(find.text('Save address'), findsOneWidget);

      await tester.tap(find.text('Save address'));
      await advance(tester); // sheet dismissed, result returned
      await advance(tester); // host rebuild

      expect(find.text('result:${address.displayName}'), findsOneWidget);
    });
  });
}
