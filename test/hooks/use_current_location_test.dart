import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:kryonex_address_picker/src/hooks/use_current_location.dart';
import 'package:mocktail/mocktail.dart';

import '../_support/fake_geolocator.dart';

void main() {
  group('useCurrentLocation', () {
    CurrentLocationState? captured;

    Widget buildHarness() {
      return MaterialApp(
        home: HookBuilder(
          builder: (context) {
            captured = useCurrentLocation();
            return ElevatedButton(
              onPressed: () => captured!.fetch(),
              child: const Text('fetch'),
            );
          },
        ),
      );
    }

    testWidgets('services disabled returns error', (tester) async {
      installGeolocatorMock(serviceEnabled: false);
      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('fetch'));
      await tester.pumpAndSettle();

      expect(captured!.error, contains('Location services are disabled'));
      expect(captured!.location, isNull);
      expect(captured!.isLoading, isFalse);
    });

    testWidgets('permission denied after request returns error',
        (tester) async {
      installGeolocatorMock(
        checkPermission: LocationPermission.denied,
        requestPermission: LocationPermission.denied,
      );
      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('fetch'));
      await tester.pumpAndSettle();

      expect(captured!.error, 'Location permission denied.');
      expect(captured!.location, isNull);
      expect(captured!.isLoading, isFalse);
    });

    testWidgets('generic exception returns fallback error', (tester) async {
      final mock = installGeolocatorMock();
      when(() => mock.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenThrow(Exception('GPS hardware failure'));

      await tester.pumpWidget(buildHarness());

      await tester.tap(find.text('fetch'));
      await tester.pumpAndSettle();

      expect(captured!.error, 'Failed to get current location.');
      expect(captured!.location, isNull);
      expect(captured!.isLoading, isFalse);
    });
  });
}
