<div align="center">

# ◆ kryonex_address_picker

**A search-first address picker for Flutter.**
Geocoding · map confirmation · structured output — in one call.

`showAddressPicker(context)` → a fully-typed address.

<!-- pub.dev badges resolve once the package is published to pub.dev -->
[![Pub Version](https://img.shields.io/pub/v/kryonex_address_picker.svg)](https://pub.dev/packages/kryonex_address_picker)
[![Pub Likes](https://img.shields.io/pub/likes/kryonex_address_picker)](https://pub.dev/packages/kryonex_address_picker)
[![Pub Points](https://img.shields.io/pub/points/kryonex_address_picker)](https://pub.dev/packages/kryonex_address_picker)
[![Pub Popularity](https://img.shields.io/pub/popularity/kryonex_address_picker)](https://pub.dev/packages/kryonex_address_picker)

[![GitHub Stars](https://img.shields.io/github/stars/Kryonex-Labs/kryonex_address_picker?style=social)](https://github.com/Kryonex-Labs/kryonex_address_picker)
[![GitHub Forks](https://img.shields.io/github/forks/Kryonex-Labs/kryonex_address_picker?style=social)](https://github.com/Kryonex-Labs/kryonex_address_picker)
[![GitHub Issues](https://img.shields.io/github/issues/Kryonex-Labs/kryonex_address_picker)](https://github.com/Kryonex-Labs/kryonex_address_picker/issues)
[![Last Commit](https://img.shields.io/github/last-commit/Kryonex-Labs/kryonex_address_picker)](https://github.com/Kryonex-Labs/kryonex_address_picker/commits)

[![License](https://img.shields.io/github/license/Kryonex-Labs/kryonex_address_picker)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS-blue)](https://github.com/Kryonex-Labs/kryonex_address_picker)
[![Dart](https://img.shields.io/badge/Dart-%5E3.11-0175C2?logo=dart)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.41-02569B?logo=flutter)](https://flutter.dev)

[![Style](https://img.shields.io/badge/style-flutter__lints-40c4ff.svg)](https://pub.dev/packages/flutter_lints)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Kryonex-Labs/kryonex_address_picker/pulls)
[![Kryonex Labs](https://img.shields.io/badge/Kryonex%20Labs-FF6F00)](https://github.com/Kryonex-Labs)

— built by **[Kryonex Labs](https://github.com/kryonex)** —

</div>

---

## ⟶ Demo

<div align="center">

<video src="https://github.com/Kryonex-Labs/kryonex_address_picker/raw/develop/assets/example.mp4" controls width="320"></video>

_Search · confirm on map · capture details — all in one flow._

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
      AddressFieldSpec.apt,
      AddressFieldSpec.deliveryNotes,
    ],
  ),
);
```

### Configurable detail fields

The detail step is a frosted-glass bottom sheet presented over the confirmed
map. Its fields are fully composable via `AddressFieldSpec`: mix the built-in
presets with your own custom fields, with per-field icons, validation,
keyboard types, and quick-fill chips.

Built-in presets: `AddressFieldSpec.apt`, `.floor`, and `.deliveryNotes` (the
default set), plus `.postalCode` (opt-in — handy for international addresses).

```dart
config: AddressPickerConfig(
  detailFields: [
    AddressFieldSpec.apt,          // built-in preset
    AddressFieldSpec.floor,        // built-in preset
    AddressFieldSpec(              // custom field
      key: 'gate',
      label: 'Gate code',
      icon: Icons.pin_outlined,
      keyboardType: TextInputType.number,
      required: true,
      quickFills: ['1234', '0000'],
    ),
    AddressFieldSpec.deliveryNotes,
  ],
),

// Read values back by key:
result.details?['gate'];      // "1234"
result.details?.apt;          // built-in convenience getter, still works
```

The sheet's appearance is configurable too — see `detailSheetTitle`,
`detailSheetSubtitle`, `saveButtonLabel`, `sheetBlurSigma`,
`sheetCornerRadius`, `sheetAccentColor`, `showDragHandle`, `sheetDismissible`,
and `sheetEnableDrag` in the table below.

## ⟶ Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `theme` | `FThemeData?` | `null` | Explicit ForUI theme (highest priority) |
| `materialTheme` | `ThemeData?` | `null` | Material theme to auto-bridge |
| `initialLocation` | `LatLng?` | `null` | Initial map center |
| `countryCodes` | `List<String>?` | `null` | ISO country-code filter for search (takes priority over `localeAwareSearch`) |
| `localeAwareSearch` | `bool` | `true` | Auto-restrict results to the device locale's country (ignored when `countryCodes` is set) |
| `maxRecentAddresses` | `int` | `5` | Max recent addresses to store |
| `showDetailScreen` | `bool` | `true` | Show the detail sheet after map confirm |
| `detailFields` | `List<AddressFieldSpec>?` | apt, floor, notes | Which detail fields to display, and in what order |
| `searchHint` | `String?` | `null` | Search bar placeholder (falls back to `"Search for an address..."`) |
| `mapZoom` | `double` | `16.0` | Default map zoom level |
| `detailSheetTitle` | `String` | `"Add details"` | Title at the top of the detail sheet |
| `detailSheetSubtitle` | `String?` | `null` | Optional subtitle under the title |
| `saveButtonLabel` | `String` | `"Save address"` | Label for the sheet's save button |
| `sheetBlurSigma` | `double` | `18.0` | Backdrop blur strength behind the sheet |
| `sheetCornerRadius` | `double` | `28.0` | Sheet top corner radius |
| `sheetAccentColor` | `Color?` | theme primary | Glow colour of the save button |
| `showDragHandle` | `bool` | `true` | Show the drag handle |
| `sheetDismissible` | `bool` | `true` | Tap-scrim to dismiss |
| `sheetEnableDrag` | `bool` | `true` | Drag-down to dismiss |

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
  final Map<String, String?> values; // keyed by AddressFieldSpec.key

  String? operator [](String key);   // values['gate']
  String? get apt;                   // convenience: values['apt']
  String? get floor;                 // convenience: values['floor']
  String? get deliveryNotes;         // convenience: values['deliveryNotes']

  bool get isEmpty;                  // true when no field has a value
  bool get isNotEmpty;
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
