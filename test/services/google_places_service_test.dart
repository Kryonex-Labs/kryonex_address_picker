import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kryonex_address_picker/src/services/google_places_service.dart';
import 'package:mocktail/mocktail.dart';

import '../_support/fixtures.dart';
import '../_support/mock_http.dart';

void main() {
  setUpAll(registerHttpFallbacks);

  late MockHttpClient client;
  late GooglePlacesService service;

  setUp(() {
    client = MockHttpClient();
    service = GooglePlacesService(apiKey: 'test-key', client: client);
  });

  // ── Stubs ─────────────────────────────────────────────────────────────────

  /// Stubs `client.get` to return [response] and captures the POST body via
  /// the invocation so tests can inspect it later.
  void stubGet(http.Response response) {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => response);
  }

  String? _lastPostBody;

  /// Stubs `client.post` to return [response], recording the raw body string.
  void stubPost(http.Response response) {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer((invocation) async {
      _lastPostBody =
          invocation.namedArguments[const Symbol('body')] as String?;
      return response;
    });
  }

  Uri capturedGetUri() {
    final captured =
        verify(() => client.get(captureAny(), headers: any(named: 'headers')))
            .captured;
    return captured.last as Uri;
  }

  Uri capturedPostUri() {
    final captured = verify(
      () => client.post(
        captureAny(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).captured;
    return captured.last as Uri;
  }

  // ── autocomplete ──────────────────────────────────────────────────────────

  group('GooglePlacesService.autocomplete', () {
    test('returns [] without hitting the network for empty/blank query',
        () async {
      expect(await service.autocomplete(''), isEmpty);
      expect(await service.autocomplete('   '), isEmpty);
      verifyNever(
        () => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
    });

    test('parses placeId, mainText, secondaryText, and fullText', () async {
      stubPost(httpResponse(placesAutocompleteBody()));

      final results = await service.autocomplete('1 Main');

      expect(results, hasLength(1));
      expect(results.single.placeId, 'ChIJdd4hrwug2EcRmSrV3Vo6llI');
      expect(results.single.mainText, '1 Main Street');
      expect(results.single.secondaryText, 'London, UK');
      expect(results.single.fullText, '1 Main Street, London, UK');
    });

    test('falls back to empty string when secondaryText is absent', () async {
      stubPost(httpResponse(
        json.encode({'suggestions': [placeSuggestionNoSecondary]}),
      ));

      final results = await service.autocomplete('MG Road');

      expect(results.single.secondaryText, isEmpty);
    });

    test('falls back to fullText for mainText when structuredFormat is absent',
        () async {
      const noFormat = {
        'placePrediction': {
          'placeId': 'no-format-id',
          'text': {'text': 'Full Text Only'},
          // structuredFormat absent
        },
      };
      stubPost(httpResponse(json.encode({
        'suggestions': [noFormat],
      })));

      final results = await service.autocomplete('anything');

      expect(results.single.mainText, 'Full Text Only');
    });

    test('returns [] when suggestions key is absent or empty', () async {
      stubPost(httpResponse(placesEmptyAutocompleteBody()));
      expect(await service.autocomplete('query'), isEmpty);
    });

    test('respects the limit parameter', () async {
      // Build response with 3 suggestions.
      final body = json.encode({
        'suggestions': List.generate(3, (i) => {
              'placePrediction': {
                'placeId': 'id$i',
                'text': {'text': 'Place $i'},
                'structuredFormat': {
                  'mainText': {'text': 'Place $i'},
                },
              },
            }),
      });
      stubPost(httpResponse(body));

      final results = await service.autocomplete('place', limit: 2);
      expect(results, hasLength(2));
    });

    test('sends request to the Places API autocomplete endpoint', () async {
      stubPost(httpResponse(placesEmptyAutocompleteBody()));

      await service.autocomplete('cafe');

      final uri = capturedPostUri();
      expect(uri.host, 'places.googleapis.com');
      expect(uri.path, '/v1/places:autocomplete');
    });

    test('includes input in POST body', () async {
      stubPost(httpResponse(placesEmptyAutocompleteBody()));

      await service.autocomplete('coffee shop');

      final body = json.decode(_lastPostBody!) as Map<String, dynamic>;
      expect(body['input'], 'coffee shop');
    });

    test('includes sessionToken in POST body', () async {
      stubPost(httpResponse(placesEmptyAutocompleteBody()));

      await service.autocomplete('anything');

      final body = json.decode(_lastPostBody!) as Map<String, dynamic>;
      expect(body['sessionToken'], isNotEmpty);
    });

    test('includes languageCode in body when lang is provided', () async {
      stubPost(httpResponse(placesEmptyAutocompleteBody()));

      await service.autocomplete('cafe', lang: 'de');

      final body = json.decode(_lastPostBody!) as Map<String, dynamic>;
      expect(body['languageCode'], 'de');
    });

    test('omits languageCode when lang is null', () async {
      stubPost(httpResponse(placesEmptyAutocompleteBody()));

      await service.autocomplete('cafe');

      final body = json.decode(_lastPostBody!) as Map<String, dynamic>;
      expect(body.containsKey('languageCode'), isFalse);
    });

    test('throws ClientException on non-200 HTTP status', () {
      stubPost(httpResponse('Unauthorized', status: 401));

      expect(
        () => service.autocomplete('cafe'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  // ── placeDetails ──────────────────────────────────────────────────────────

  group('GooglePlacesService.placeDetails', () {
    test('calls the correct Places API endpoint', () async {
      stubGet(httpResponse(placeDetailsBody()));

      await service.placeDetails('ChIJdd4hrwug2EcRmSrV3Vo6llI');

      final uri = capturedGetUri();
      expect(uri.host, 'places.googleapis.com');
      expect(uri.path, '/v1/places/ChIJdd4hrwug2EcRmSrV3Vo6llI');
    });

    test('includes sessionToken as a query parameter', () async {
      stubGet(httpResponse(placeDetailsBody()));

      await service.placeDetails('place-id');

      final uri = capturedGetUri();
      expect(uri.queryParameters.containsKey('sessionToken'), isTrue);
      expect(uri.queryParameters['sessionToken'], isNotEmpty);
    });

    test('returns a GeocodingResult with correct coordinates', () async {
      stubGet(httpResponse(placeDetailsBody()));

      final result = await service.placeDetails('ChIJdd4hrwug2EcRmSrV3Vo6llI');

      expect(result, isNotNull);
      expect(result!.lat, closeTo(51.5074, 1e-9));
      expect(result.lon, closeTo(-0.1278, 1e-9));
    });

    test('returns a GeocodingResult with correct placeId and address',
        () async {
      stubGet(httpResponse(placeDetailsBody()));

      final result = await service.placeDetails('ChIJdd4hrwug2EcRmSrV3Vo6llI');

      expect(result!.placeId, 'ChIJdd4hrwug2EcRmSrV3Vo6llI');
      expect(result.displayName, contains('1 Main Street'));
    });

    test('resets sessionToken after a successful call', () async {
      stubGet(httpResponse(placeDetailsBody()));

      await service.placeDetails('place1');
      await service.placeDetails('place2');

      // Capture both GET URIs.
      final captured = verify(
        () => client.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      expect(captured, hasLength(2));
      final token1 =
          (captured[0] as Uri).queryParameters['sessionToken'];
      final token2 =
          (captured[1] as Uri).queryParameters['sessionToken'];
      expect(token1, isNotEmpty);
      expect(token2, isNotEmpty);
      expect(token1, isNot(equals(token2)));
    });

    test('resets sessionToken even after a non-200 response', () async {
      // First call fails.
      stubGet(httpResponse('error', status: 503));
      try {
        await service.placeDetails('bad-id');
      } catch (_) {}

      // Second call succeeds — stub fresh.
      stubGet(httpResponse(placeDetailsBody()));
      await service.placeDetails('good-id');

      final captured = verify(
        () => client.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final token1 = (captured[0] as Uri).queryParameters['sessionToken'];
      final token2 = (captured[1] as Uri).queryParameters['sessionToken'];
      // Tokens must differ because the first call reset before throwing.
      expect(token1, isNot(equals(token2)));
    });

    test('throws ClientException on non-200 HTTP status', () {
      stubGet(httpResponse('Not Found', status: 404));

      expect(
        () => service.placeDetails('bad-id'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  // ── search (Google Geocoding API) ─────────────────────────────────────────

  group('GooglePlacesService.search', () {
    test('returns [] without hitting the network for empty/blank query',
        () async {
      expect(await service.search(''), isEmpty);
      expect(await service.search('   '), isEmpty);
      verifyNever(
        () => client.get(any(), headers: any(named: 'headers')),
      );
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

      final uri = capturedGetUri();
      expect(uri.host, 'maps.googleapis.com');
      expect(uri.path, '/maps/api/geocode/json');
      expect(uri.queryParameters['address'], 'cafe');
      expect(uri.queryParameters['key'], 'test-key');
    });

    test('includes language param when lang provided', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe', lang: 'fr');

      expect(capturedGetUri().queryParameters['language'], 'fr');
    });

    test('omits language param when lang is null', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe');

      expect(
        capturedGetUri().queryParameters.containsKey('language'),
        isFalse,
      );
    });

    test('formats country codes as pipe-separated components param', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe', countryCodes: ['in', 'gb']);

      expect(
        capturedGetUri().queryParameters['components'],
        'country:IN|country:GB',
      );
    });

    test('omits components param when countryCodes is null', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.search('cafe');

      expect(
        capturedGetUri().queryParameters.containsKey('components'),
        isFalse,
      );
    });

    test('returns [] for ZERO_RESULTS status', () async {
      stubGet(httpResponse(googleEmptyBody()));

      expect(await service.search('nonexistent'), isEmpty);
    });

    test('limits results to the limit parameter', () async {
      final body =
          '{"status":"OK","results":[${List.filled(3, '{"place_id":"a","formatted_address":"A","geometry":{"location":{"lat":0,"lng":0}},"address_components":[]}').join(',')}]}';
      stubGet(httpResponse(body));

      final results = await service.search('query', limit: 2);

      expect(results, hasLength(2));
    });

    test('throws ClientException on non-200 HTTP status', () {
      stubGet(httpResponse('error', status: 500));

      expect(
        () => service.search('cafe'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('throws ClientException on API error status (REQUEST_DENIED)',
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
  });

  // ── reverse ───────────────────────────────────────────────────────────────

  group('GooglePlacesService.reverse', () {
    test('resolves the first result into a StructuredAddress', () async {
      stubGet(httpResponse(googleSearchBody()));

      final address = await service.reverse(12.9716, 77.5946);

      expect(address, isNotNull);
      expect(address!.street, 'Mahatma Gandhi Road');
      expect(address.city, 'Bengaluru');
      expect(address.state, 'Karnataka');
      expect(address.postalCode, '560001');
      expect(address.country, 'India');
      expect(address.countryCode, 'in');
    });

    test('builds URI with latlng and key', () async {
      stubGet(httpResponse(googleEmptyBody()));

      await service.reverse(1.5, -2.5);

      final uri = capturedGetUri();
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

    test('throws ClientException on non-200 HTTP status', () {
      stubGet(httpResponse('error', status: 403));

      expect(
        () => service.reverse(0, 0),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  // ── dispose ───────────────────────────────────────────────────────────────

  group('GooglePlacesService.dispose', () {
    test('closes the HTTP client', () {
      service.dispose();

      verify(() => client.close()).called(1);
    });
  });

  // ── supportsAutocomplete ─────────────────────────────────────────────────

  group('GooglePlacesService.supportsAutocomplete', () {
    test('returns true', () {
      expect(service.supportsAutocomplete, isTrue);
    });
  });
}
