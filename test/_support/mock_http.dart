import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

/// A mocktail mock of [http.Client] for [PhotonService] unit tests.
///
/// The service exposes an injectable `client` parameter, so these tests need
/// no `HttpOverrides` — they stub `get` directly.
class MockHttpClient extends Mock implements http.Client {}

/// Registers fallback values required by mocktail's `any()` matchers.
///
/// Call once in `setUpAll`.
void registerHttpFallbacks() {
  registerFallbackValue(Uri.parse('https://photon.komoot.io/'));
}

/// Convenience builder for an [http.Response].
http.Response httpResponse(String body, {int status = 200}) =>
    http.Response(body, status);
