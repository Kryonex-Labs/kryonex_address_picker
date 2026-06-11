import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kryonex_address_picker/src/services/google_geocoding_service.dart';
import 'package:mocktail/mocktail.dart';

import '../_support/fixtures.dart';
import '../_support/mock_http.dart';

void main() {
  setUpAll(registerHttpFallbacks);

  late MockHttpClient client;
  late GoogleGeocodingService service;

  setUp(() {
    client = MockHttpClient();
    service = GoogleGeocodingService(apiKey: 'test-key', client: client);
  });

  // Stubs `client.get` to return [response] regardless of URI.
  void stubGet(http.Response response) {
    when(() => client.get(any())).thenAnswer((_) async => response);
  }

  // Captures the URI passed to the last `client.get` call.
  Uri capturedUri() {
    final captured = verify(() => client.get(captureAny())).captured;
    return captured.last as Uri;
  }

  group('GoogleGeocodingService.search', () {
    test('returns [] without hitting the network for empty/blank query',
        () async {
      expect(await service.search(''), isEmpty);
      expect(await service.search('   '), isEmpty);
      verifyNever(() => client.get(any()));
    });

    test('parses results into GeocodingResults', () async {
      stubGet(httpResponse(googleSearchBody()));

      final results = await service.search('MG Road');

      expect(results, hasLength(1));
      expect(results.single.placeId, 'ChIJkbeSa_BfYzARphNChaFPjNc');
      expect(results.single.displayName, contains('Mahatma Gandhi Road'));
      expect(results.single.lat, closeTo(12.9716, 1e-9));
      expect(results.single.lon, closeTo(77.5946, 1e-9));
    });

    test('builds URI with address, key and base URL', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe');

      final uri = capturedUri();
      expect(uri.host, 'maps.googleapis.com');
      expect(uri.path, '/maps/api/geocode/json');
      expect(uri.queryParameters['address'], 'cafe');
      expect(uri.queryParameters['key'], 'test-key');
    });

    test('includes language param when provided', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe', lang: 'de');

      expect(capturedUri().queryParameters['language'], 'de');
    });

    test('omits language param when not provided', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe');

      expect(
        capturedUri().queryParameters.containsKey('language'),
        isFalse,
      );
    });

    test('formats country codes as pipe-separated components param', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe', countryCodes: ['in', 'us']);

      expect(
        capturedUri().queryParameters['components'],
        'country:IN|country:US',
      );
    });

    test('omits components param when countryCodes is null', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe');

      expect(
        capturedUri().queryParameters.containsKey('components'),
        isFalse,
      );
    });

    test('returns [] for ZERO_RESULTS status', () async {
      stubGet(httpResponse(googleEmptyBody()));

      expect(await service.search('nonexistent place'), isEmpty);
    });

    test('limits results to the limit parameter', () async {
      // Build a response with 3 results.
      final body = '{"status":"OK","results":[${List.filled(3, '{"place_id":"a","formatted_address":"A","geometry":{"location":{"lat":0,"lng":0}},"address_components":[]}').join(',')}]}';
      stubGet(httpResponse(body));

      final results = await service.search('query', limit: 2);

      expect(results, hasLength(2));
    });

    test('throws ClientException on non-200 HTTP status', () async {
      stubGet(httpResponse('error', status: 500));

      expect(
        () => service.search('cafe'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('throws ClientException on API error status (e.g. REQUEST_DENIED)',
        () async {
      stubGet(httpResponse(googleErrorBody('REQUEST_DENIED')));

      expect(
        () => service.search('cafe'),
        throwsA(
          isA<http.ClientException>().having(
            (e) => e.message,
            'message',
            contains('REQUEST_DENIED'),
          ),
        ),
      );
    });

    test('throws on OVER_QUERY_LIMIT status', () async {
      stubGet(httpResponse(googleErrorBody('OVER_QUERY_LIMIT')));

      expect(
        () => service.search('cafe'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('GoogleGeocodingService.reverse', () {
    test('resolves the first result into a StructuredAddress', () async {
      stubGet(httpResponse(googleSearchBody()));

      final address = await service.reverse(12.9716, 77.5946);

      expect(address, isNotNull);
      expect(address!.street, 'Mahatma Gandhi Road');
      expect(address.houseNumber, '12');
      expect(address.city, 'Bengaluru');
      expect(address.state, 'Karnataka');
      expect(address.postalCode, '560001');
      expect(address.country, 'India');
      expect(address.countryCode, 'in');
    });

    test('builds URI with latlng and key', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.reverse(1.5, -2.5);

      final uri = capturedUri();
      expect(uri.queryParameters['latlng'], '1.5,-2.5');
      expect(uri.queryParameters['key'], 'test-key');
    });

    test('returns null for non-OK API status', () async {
      stubGet(httpResponse(googleEmptyBody()));

      expect(await service.reverse(0, 0), isNull);
    });

    test('returns null when results list is empty', () async {
      stubGet(httpResponse('{"status":"OK","results":[]}'));

      expect(await service.reverse(0, 0), isNull);
    });

    test('throws ClientException on non-200 HTTP status', () async {
      stubGet(httpResponse('error', status: 403));

      expect(
        () => service.reverse(0, 0),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('GoogleGeocodingService.dispose', () {
    test('closes the HTTP client', () {
      service.dispose();

      verify(() => client.close()).called(1);
    });
  });
}
