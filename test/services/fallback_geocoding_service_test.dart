import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/src/models/geocoding_result.dart';
import 'package:kryonex_address_picker/src/models/structured_address.dart';
import 'package:kryonex_address_picker/src/services/fallback_geocoding_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../_support/mock_geocoding.dart';

void main() {
  setUpAll(registerGeocodingFallbacks);

  late MockGeocodingService primary;
  late MockGeocodingService fallback;
  late FallbackGeocodingService service;

  setUp(() {
    primary = MockGeocodingService();
    fallback = MockGeocodingService();
    service = FallbackGeocodingService(primary: primary, fallback: fallback);
  });

  // ── Canonical test data ─────────────────────────────────────────────────

  final sampleResults = [
    const GeocodingResult(
      placeId: '1',
      displayName: 'Primary Result',
      lat: 12.0,
      lon: 77.0,
      addressParts: {},
    ),
  ];

  final fallbackResults = [
    const GeocodingResult(
      placeId: '2',
      displayName: 'Fallback Result',
      lat: 13.0,
      lon: 78.0,
      addressParts: {},
    ),
  ];

  const sampleAddress = StructuredAddress(
    displayName: 'Primary Address',
    latLng: LatLng(12.0, 77.0),
  );

  const fallbackAddress = StructuredAddress(
    displayName: 'Fallback Address',
    latLng: LatLng(13.0, 78.0),
  );

  group('FallbackGeocodingService.search', () {
    test('returns primary results when primary succeeds', () async {
      when(
        () => primary.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => sampleResults);

      final results = await service.search('query');

      expect(results, sampleResults);
      verifyNever(
        () => fallback.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('falls back when primary throws', () async {
      when(
        () => primary.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('Google API down'));

      when(
        () => fallback.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => fallbackResults);

      final results = await service.search('query');

      expect(results, fallbackResults);
    });

    test('propagates all parameters to primary', () async {
      when(
        () => primary.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => sampleResults);

      await service.search(
        'MG Road',
        countryCodes: ['IN', 'US'],
        lang: 'en',
        limit: 3,
      );

      verify(
        () => primary.search(
          'MG Road',
          countryCodes: ['IN', 'US'],
          lang: 'en',
          limit: 3,
        ),
      ).called(1);
    });

    test('propagates all parameters to fallback on primary failure', () async {
      when(
        () => primary.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('boom'));

      when(
        () => fallback.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => fallbackResults);

      await service.search(
        'MG Road',
        countryCodes: ['IN'],
        lang: 'de',
        limit: 7,
      );

      verify(
        () => fallback.search(
          'MG Road',
          countryCodes: ['IN'],
          lang: 'de',
          limit: 7,
        ),
      ).called(1);
    });

    test('rethrows when both primary and fallback throw', () async {
      when(
        () => primary.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('primary down'));

      when(
        () => fallback.search(
          any(),
          countryCodes: any(named: 'countryCodes'),
          lang: any(named: 'lang'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('fallback also down'));

      expect(
        () => service.search('query'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('fallback also down'),
          ),
        ),
      );
    });
  });

  group('FallbackGeocodingService.reverse', () {
    test('returns primary address when primary succeeds', () async {
      when(() => primary.reverse(any(), any()))
          .thenAnswer((_) async => sampleAddress);

      final result = await service.reverse(12.0, 77.0);

      expect(result, sampleAddress);
      verifyNever(() => fallback.reverse(any(), any()));
    });

    test('falls back when primary throws', () async {
      when(() => primary.reverse(any(), any()))
          .thenThrow(Exception('API down'));

      when(() => fallback.reverse(any(), any()))
          .thenAnswer((_) async => fallbackAddress);

      final result = await service.reverse(12.0, 77.0);

      expect(result, fallbackAddress);
    });

    test('rethrows when both primary and fallback throw', () async {
      when(() => primary.reverse(any(), any()))
          .thenThrow(Exception('primary'));
      when(() => fallback.reverse(any(), any()))
          .thenThrow(Exception('fallback'));

      expect(
        () => service.reverse(0, 0),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('fallback'),
          ),
        ),
      );
    });
  });

  group('FallbackGeocodingService.dispose', () {
    test('disposes both primary and fallback', () {
      service.dispose();

      verify(() => primary.dispose()).called(1);
      verify(() => fallback.dispose()).called(1);
    });
  });
}
