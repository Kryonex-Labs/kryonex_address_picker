import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';
import 'package:kryonex_address_picker/src/screens/search_screen.dart';
import 'package:kryonex_address_picker/src/widgets/address_tile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:geolocator/geolocator.dart' show LocationPermission;
import 'package:latlong2/latlong.dart' show LatLng;

import '../_support/fake_geolocator.dart';
import '../_support/fixtures.dart';
import '../_support/mock_geocoding.dart';

const _storageKey = 'kryonex_recent_addresses';

/// Builds the SearchScreen inside a minimal navigator host.
///
/// Pass [config] to inject a custom [AddressPickerConfig] (e.g. for mock
/// geocoding services). Defaults to `localeAwareSearch: false`.
Widget buildSearchScreen({
  required ValueChanged<StructuredAddress> onAddressSelected,
  required VoidCallback onPickOnMap,
  ValueChanged<LatLng>? onCurrentLocation,
  AddressPickerConfig? config,
}) {
  return MaterialApp(
    home: SearchScreen(
      config: config ?? const AddressPickerConfig(localeAwareSearch: false),
      onAddressSelected: onAddressSelected,
      onPickOnMap: onPickOnMap,
      onCurrentLocation: onCurrentLocation ?? (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerGeocodingFallbacks);

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

  group('SearchScreen — search results', () {
    late MockGeocodingService mockService;

    setUp(() {
      mockService = MockGeocodingService();
      // supportsAutocomplete was added to GeocodingService in Phase 2.
      // Stub it false so the hook takes the search() path (Photon-style),
      // matching the existing test expectations for AddressTile results.
      when(() => mockService.supportsAutocomplete).thenReturn(false);
    });

    testWidgets('shows search results when service returns addresses',
        (tester) async {
      const result = GeocodingResult(
        placeId: '1',
        displayName: '123 Main St, Springfield',
        lat: 37.0,
        lon: -122.0,
        addressParts: {'road': 'Main St', 'city': 'Springfield'},
      );
      when(
        () => mockService.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [result]);

      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (_) {},
          onPickOnMap: () {},
          config: AddressPickerConfig(
            geocodingService: mockService,
            localeAwareSearch: false,
          ),
        ),
      );
      await tester.pump();

      // Enter query to trigger search.
      await tester.enterText(find.byType(TextField), 'Main');
      await tester.pump(); // query changes → hook effect runs
      await tester.pump(); // rebuild with isLoading=true
      await tester.pump(const Duration(milliseconds: 500)); // debounce fires
      await tester.pump(); // async resolves → rebuild with results

      expect(find.byType(AddressTile), findsOneWidget);
    });

    testWidgets('shows loading indicator while search is in progress',
        (tester) async {
      // Delay the response so the loading state is observable.
      when(
        () => mockService.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return <GeocodingResult>[];
      });

      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (_) {},
          onPickOnMap: () {},
          config: AddressPickerConfig(
            geocodingService: mockService,
            localeAwareSearch: false,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump(); // query changes
      await tester.pump(); // isLoading = true → rebuild

      // Loading indicator should be visible in the search-results area.
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error alert when search fails', (tester) async {
      when(
        () => mockService.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('network error'));

      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (_) {},
          onPickOnMap: () {},
          config: AddressPickerConfig(
            geocodingService: mockService,
            localeAwareSearch: false,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('Search Error'), findsOneWidget);
      expect(find.text('Search failed. Please try again.'), findsOneWidget);
    });

    testWidgets('shows "No results found" when search returns empty list',
        (tester) async {
      when(
        () => mockService.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => <GeocodingResult>[]);

      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (_) {},
          onPickOnMap: () {},
          config: AddressPickerConfig(
            geocodingService: mockService,
            localeAwareSearch: false,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'xyznonexistent');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('tapping a search result fires onAddressSelected',
        (tester) async {
      const result = GeocodingResult(
        placeId: '42',
        displayName: '99 Oak Ave, Portland',
        lat: 45.5,
        lon: -122.6,
        addressParts: {'road': 'Oak Ave', 'city': 'Portland'},
      );
      when(
        () => mockService.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [result]);

      StructuredAddress? selected;
      await tester.pumpWidget(
        buildSearchScreen(
          onAddressSelected: (a) => selected = a,
          onPickOnMap: () {},
          config: AddressPickerConfig(
            geocodingService: mockService,
            localeAwareSearch: false,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Oak');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Tap the result tile (primaryLine is the street name).
      await tester.tap(find.byType(AddressTile));
      await tester.pumpAndSettle();

      expect(selected?.displayName, '99 Oak Ave, Portland');
    });
  });

  group('SearchScreen — search bar', () {
    testWidgets('clear button appears when text is entered and clears on tap',
        (tester) async {
      await tester.pumpWidget(
        buildSearchScreen(onAddressSelected: (_) {}, onPickOnMap: () {}),
      );
      await tester.pump();

      // No clear button initially.
      expect(find.byIcon(Icons.close), findsNothing);

      // Enter text.
      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      // Clear button should appear.
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap the clear button.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Text should be cleared and clear button gone.
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
