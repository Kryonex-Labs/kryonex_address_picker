import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kryonex_address_picker/src/services/photon_service.dart';
import 'package:mocktail/mocktail.dart';

import '../_support/fixtures.dart';
import '../_support/mock_http.dart';

void main() {
  setUpAll(registerHttpFallbacks);

  late MockHttpClient client;
  late PhotonService service;

  setUp(() {
    client = MockHttpClient();
    service = PhotonService(client: client);
  });

  // Stubs `client.get` to return [response] regardless of URI.
  void stubGet(http.Response response) {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => response);
  }

  // Captures the URI passed to the last `client.get` call.
  Uri capturedUri() {
    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    return captured.single as Uri;
  }

  group('PhotonService.search', () {
    test('returns [] without hitting the network for empty/blank query',
        () async {
      expect(await service.search(''), isEmpty);
      expect(await service.search('   '), isEmpty);
      verifyNever(() => client.get(any(), headers: any(named: 'headers')));
    });

    test('parses features into GeocodingResults', () async {
      stubGet(httpResponse(photonSearchBody()));

      final results = await service.search('MG Road');

      expect(results, hasLength(1));
      expect(results.single.displayName, contains('MG Road'));
      expect(results.single.latLng.latitude, closeTo(12.9716, 1e-9));
    });

    test('builds the request URI with q, limit and uppercased countrycodes',
        () async {
      stubGet(httpResponse(photonEmptyBody()));

      await service.search(
        'cafe',
        countryCodes: ['in', 'us'],
        lang: 'en',
        limit: 3,
      );

      final uri = capturedUri();
      expect(uri.host, 'photon.komoot.io');
      expect(uri.path, '/api/');
      expect(uri.queryParameters['q'], 'cafe');
      expect(uri.queryParameters['limit'], '3');
      expect(uri.queryParameters['lang'], 'en');
      // Country codes are uppercased and repeated.
      expect(uri.queryParametersAll['countrycode'], ['IN', 'US']);
    });

    test('omits lang when not provided', () async {
      stubGet(httpResponse(photonEmptyBody()));
      await service.search('cafe');
      expect(capturedUri().queryParameters.containsKey('lang'), isFalse);
    });

    test('sends User-Agent and Accept headers', () async {
      stubGet(httpResponse(photonEmptyBody()));
      await service.search('cafe');

      final headers = verify(
        () => client.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;
      expect(headers['User-Agent'], service.userAgent);
      expect(headers['Accept'], 'application/json');
    });

    test('returns [] on non-200 status', () async {
      stubGet(httpResponse('error', status: 500));
      expect(await service.search('cafe'), isEmpty);
    });

    test('returns [] on malformed JSON', () async {
      stubGet(httpResponse(malformedBody));
      expect(await service.search('cafe'), isEmpty);
    });

    test('returns [] when the client throws', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('network down'));
      expect(await service.search('cafe'), isEmpty);
    });
  });

  group('PhotonService.reverse', () {
    test('resolves the first feature into a StructuredAddress', () async {
      stubGet(httpResponse(photonSearchBody()));

      final address = await service.reverse(12.9716, 77.5946);

      expect(address, isNotNull);
      expect(address!.city, 'Bengaluru');
      expect(address.countryCode, 'in');
    });

    test('builds reverse URI with lat, lon and limit=1', () async {
      stubGet(httpResponse(photonEmptyBody()));
      await service.reverse(1.5, -2.5);

      final uri = capturedUri();
      expect(uri.path, '/reverse');
      expect(uri.queryParameters['lat'], '1.5');
      expect(uri.queryParameters['lon'], '-2.5');
      expect(uri.queryParameters['limit'], '1');
    });

    test('returns null when no features', () async {
      stubGet(httpResponse(photonEmptyBody()));
      expect(await service.reverse(0, 0), isNull);
    });

    test('returns null on non-200 status', () async {
      stubGet(httpResponse('nope', status: 404));
      expect(await service.reverse(0, 0), isNull);
    });

    test('returns null on malformed JSON', () async {
      stubGet(httpResponse(malformedBody));
      expect(await service.reverse(0, 0), isNull);
    });
  });
}
