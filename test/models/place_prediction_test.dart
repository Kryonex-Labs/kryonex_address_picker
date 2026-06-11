import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  group('PlacePrediction', () {
    const full = PlacePrediction(
      placeId: 'abc123',
      mainText: 'Main Street 1',
      secondaryText: 'London, UK',
      fullText: 'Main Street 1, London, UK',
    );

    // Same placeId, different text fields.
    const samePlaceId = PlacePrediction(
      placeId: 'abc123',
      mainText: 'Other Name',
      secondaryText: 'Other Secondary',
      fullText: 'Other Full',
    );

    // Different placeId, same text.
    const differentPlaceId = PlacePrediction(
      placeId: 'xyz789',
      mainText: 'Main Street 1',
      secondaryText: 'London, UK',
      fullText: 'Main Street 1, London, UK',
    );

    test('stores all fields', () {
      expect(full.placeId, 'abc123');
      expect(full.mainText, 'Main Street 1');
      expect(full.secondaryText, 'London, UK');
      expect(full.fullText, 'Main Street 1, London, UK');
    });

    test('equality is based solely on placeId', () {
      expect(full, equals(samePlaceId));
      expect(full, isNot(equals(differentPlaceId)));
    });

    test('identical instance equals itself', () {
      expect(full, equals(full));
    });

    test('hashCode equals placeId.hashCode', () {
      expect(full.hashCode, 'abc123'.hashCode);
      // Two predictions with the same placeId must have the same hashCode.
      expect(full.hashCode, samePlaceId.hashCode);
      // Different placeId → different hashCode (very likely; not guaranteed by
      // contract, but always true for these specific values).
      expect(full.hashCode, isNot(differentPlaceId.hashCode));
    });

    test('toString includes fullText', () {
      expect(full.toString(), contains('Main Street 1, London, UK'));
    });

    test('secondaryText may be empty string', () {
      const noSecondary = PlacePrediction(
        placeId: 'no-sec',
        mainText: 'Only Main',
        secondaryText: '',
        fullText: 'Only Main',
      );
      expect(noSecondary.secondaryText, isEmpty);
    });
  });
}
