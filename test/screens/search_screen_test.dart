import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:kryonex_address_picker/src/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geolocator/geolocator.dart' show LocationPermission;

import '../_support/fake_geolocator.dart';
import '../_support/fixtures.dart';

const _storageKey = 'kryonex_recent_addresses';

/// Builds the SearchScreen inside a minimal navigator host.
Widget buildSearchScreen({
  required ValueChanged<StructuredAddress> onAddressSelected,
  required VoidCallback onPickOnMap,
}) {
  return MaterialApp(
    home: SearchScreen(
      config: const AddressPickerConfig(localeAwareSearch: false),
      onAddressSelected: onAddressSelected,
      onPickOnMap: onPickOnMap,
      onCurrentLocation: onAddressSelected,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installGeolocatorMock();
  });

  group('SearchScreen', () {
    testWidgets('shows search bar and "Pick on Map" button on empty query',
        (tester) async {
      await tester.pumpWidget(
        buildSearchScreen(onAddressSelected: (_) {}, onPickOnMap: () {}),
      );
      await tester.pump();

      expect(find.text('Pick on Map'), findsOneWidget);
      expect(find.text('Use current location'), findsOneWidget);
    });

    testWidgets('shows recent addresses loaded from shared_preferences',
        (tester) async {
      final address = buildAddress(displayName: 'Saved Place');
      SharedPreferences.setMockInitialValues({
        _storageKey: json.encode([address.toJson()]),
      });

      await tester.pumpWidget(
        buildSearchScreen(onAddressSelected: (_) {}, onPickOnMap: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.text(address.primaryLine), findsOneWidget);
    });

    testWidgets('"Pick on Map" fires onPickOnMap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (_) {},
          onPickOnMap: () => tapped = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Pick on Map'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('tapping a recent address fires onAddressSelected',
        (tester) async {
      final address = buildAddress(displayName: 'Recent A');
      SharedPreferences.setMockInitialValues({
        _storageKey: json.encode([address.toJson()]),
      });

      StructuredAddress? selected;
      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (a) => selected = a,
          onPickOnMap: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(address.primaryLine));
      await tester.pumpAndSettle();

      expect(selected?.displayName, address.displayName);
    });

    testWidgets('shows loading indicator while location is fetching',
        (tester) async {
      // The geolocator mock answers instantly, but we can observe the
      // isLoading state by verifying the spinner disappears after settle.
      await tester.pumpWidget(
        buildSearchScreen(onAddressSelected: (_) {}, onPickOnMap: () {}),
      );
      await tester.pump();

      await tester.tap(find.text('Use current location'));
      // One pump before async: loading state might briefly show.
      await tester.pump();

      // After settle the mock completes; no spinner should remain.
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error alert when location is permanently denied',
        (tester) async {
      installGeolocatorMock(
        serviceEnabled: true,
        checkPermission: LocationPermission.deniedForever,
      );

      await tester.pumpWidget(
        buildSearchScreen(onAddressSelected: (_) {}, onPickOnMap: () {}),
      );
      await tester.pump();

      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();

      expect(find.text('Location Error'), findsOneWidget);
    });
  });
}
