import 'package:flutter_test/flutter_test.dart';
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

void main() {
  group('map provider', () {
    test('defaults to OpenStreetMap', () {
      const config = AddressPickerConfig();

      expect(config.mapProvider, AddressPickerMapProvider.openStreetMap);
    });

    test('can select Google Maps', () {
      const config = AddressPickerConfig(
        mapProvider: AddressPickerMapProvider.googleMaps,
      );

      expect(config.mapProvider, AddressPickerMapProvider.googleMaps);
    });
  });

  group('AddressPickerConfig defaults', () {
    test('mapDarkMode defaults to auto', () {
      const config = AddressPickerConfig();
      expect(config.mapDarkMode, MapDarkMode.auto);
    });

    test('pinBuilder defaults to null', () {
      const config = AddressPickerConfig();
      expect(config.pinBuilder, isNull);
    });

    test('confirmButtonStyle defaults to null', () {
      const config = AddressPickerConfig();
      expect(config.confirmButtonStyle, isNull);
    });

    test('attributionStyle defaults to AddressPickerAttribution.osm', () {
      const config = AddressPickerConfig();
      expect(config.attributionStyle, isNotNull);
      expect(config.attributionStyle?.text, '© OpenStreetMap contributors');
    });

    test('attributionStyle can be explicitly set to null', () {
      const config = AddressPickerConfig(attributionStyle: null);
      expect(config.attributionStyle, isNull);
    });
  });

  group('AddressPickerAttribution.osm', () {
    test('has expected OSM text', () {
      expect(AddressPickerAttribution.osm.text, '© OpenStreetMap contributors');
    });

    test('has OSM copyright URI', () {
      expect(
        AddressPickerAttribution.osm.uri,
        'https://openstreetmap.org/copyright',
      );
    });

    test('defaults alignment to bottomRight', () {
      expect(
        AddressPickerAttribution.osm.alignment,
        MapAttributionAlignment.bottomRight,
      );
    });
  });

  group('MapDarkMode enum', () {
    test('has three values: auto, light, dark', () {
      expect(MapDarkMode.values, [
        MapDarkMode.auto,
        MapDarkMode.light,
        MapDarkMode.dark,
      ]);
    });
  });
}
