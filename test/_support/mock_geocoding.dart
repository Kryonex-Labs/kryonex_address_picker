import 'package:kryonex_address_picker/src/models/geocoding_result.dart';
import 'package:kryonex_address_picker/src/services/geocoding_service.dart';
import 'package:mocktail/mocktail.dart';

/// A mocktail mock of [GeocodingService] for fallback-chain tests.
class MockGeocodingService extends Mock implements GeocodingService {}

/// Registers fallback values required by mocktail's `any()` matchers
/// for [GeocodingService] method signatures.
///
/// Call once in `setUpAll`.
void registerGeocodingFallbacks() {
  registerFallbackValue(<GeocodingResult>[]);
  registerFallbackValue(<String>[]);
}
