<div align="center">

# ◆ kryonex_address_picker

**A search-first address picker for Flutter.**
Geocoding · map confirmation · structured output — in one call.

`showAddressPicker(context)` → a fully-typed address.

— built by **[Kryonex Labs](https://github.com/kryonex)** —

</div>

---

## ⟶ Why

Address entry is usually a mess of free-text fields and bad data. This is the opposite:
type, confirm on a map, done. You get back clean, structured, geocoded results.

Powered by [Komoot Photon](https://photon.komoot.io) (OpenStreetMap data, no API key),
[`flutter_map`](https://pub.dev/packages/flutter_map), and
[ForUI](https://pub.dev/packages/forui) components.

## ⟶ Features

```
◆ Search-first        debounced Photon autocomplete
◆ Map confirmation    tap-to-drop pin on an interactive OSM map
◆ Structured output   street · city · state · postal · country · latLng
◆ Address details     apt · floor · delivery notes
◆ Recent addresses    locally persisted picks
◆ Current location    one-tap geolocator support
◆ ForUI native        polished, accessible UI out of the box
◆ Zero-config theming  auto-bridges to your Material theme
```

## ⟶ Install

```yaml
dependencies:
  kryonex_address_picker: ^0.1.0
```

## ⟶ Quick Start

```dart
import 'package:kryonex_address_picker/kryonex_address_picker.dart';

final result = await showAddressPicker(context);
if (result != null) {
  result.address.displayName;   // "123 Main St, Springfield, IL 62701, USA"
  result.address.street;        // "Main Street"
  result.address.city;          // "Springfield"
  result.address.latLng;        // LatLng(39.7817, -89.6501)
  result.details?.apt;          // "Apt 4B"
  result.details?.deliveryNotes; // "Leave at the door"
}
```

With configuration:

```dart
final result = await showAddressPicker(
  context,
  config: AddressPickerConfig(
    countryCodes: ['us', 'ca'],
    maxRecentAddresses: 10,
    searchHint: 'Where to?',
    showDetailScreen: true,
    detailFields: [
      AddressDetailField.apt,
      AddressDetailField.deliveryNotes,
    ],
  ),
);
```

## ⟶ Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `theme` | `FThemeData?` | `null` | Explicit ForUI theme (highest priority) |
| `materialTheme` | `ThemeData?` | `null` | Material theme to auto-bridge |
| `initialLocation` | `LatLng?` | `null` | Initial map center |
| `countryCodes` | `List<String>?` | `null` | ISO country-code filter for search |
| `maxRecentAddresses` | `int` | `5` | Max recent addresses to store |
| `showDetailScreen` | `bool` | `true` | Show detail screen after map confirm |
| `detailFields` | `List<AddressDetailField>?` | all | Which detail fields to display |
| `searchHint` | `String?` | `"Search for an address..."` | Search bar placeholder |
| `mapZoom` | `double` | `16.0` | Default map zoom level |

## ⟶ Output Model

```dart
class SelectedAddress {
  final StructuredAddress address;
  final AddressDetails? details;
}

class StructuredAddress {
  final String displayName;     // Full address string
  final LatLng latLng;          // Geographic coordinates
  final String? street;         // "Main Street"
  final String? houseNumber;    // "123"
  final String? city;           // "Springfield"
  final String? state;          // "Illinois"
  final String? postalCode;     // "62701"
  final String? country;        // "United States"
  final String? countryCode;    // "us"
}

class AddressDetails {
  final String? apt;            // "Apt 4B"
  final String? floor;          // "3rd Floor"
  final String? deliveryNotes;  // "Leave at the door"
}
```

## ⟶ Theming

The picker adapts to your app automatically, in priority order:

```dart
// 1 — Explicit ForUI theme (highest priority)
showAddressPicker(context, config: AddressPickerConfig(
  theme: FThemes.zinc.dark,
));

// 2 — Material theme bridge
showAddressPicker(context, config: AddressPickerConfig(
  materialTheme: ThemeData(colorSchemeSeed: Colors.blue),
));

// 3 — Auto-detect (zero config)
showAddressPicker(context);
```

## ⟶ Platform Setup

### Location permissions (geolocator)

The "Use current location" feature needs platform-specific permissions.

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby addresses.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to find nearby addresses.</string>
```

**macOS** — `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.personal-information.location</key>
<true/>
```

**Web** — no setup needed; uses the browser Geolocation API.

### Internet permission (Android)

Required for Photon API calls and map tiles — `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

<div align="center">

**Kryonex Labs** · MIT License

_Geocoding by [Komoot Photon](https://photon.komoot.io) · OpenStreetMap data_

</div>
