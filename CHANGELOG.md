# Changelog

## 0.0.6

### Added
- `GeocodingService` — abstract interface for forward and reverse geocoding,
  enabling custom provider implementations. Extended with optional
  `supportsAutocomplete`, `autocomplete()`, and `placeDetails()` for
  search-as-you-type providers.
- `GooglePlacesService` — primary Google implementation using the **Places
  API (New)** for autocomplete and the **Geocoding API** for forward/reverse
  geocoding. Session-token aware for optimal Places billing.
- `GoogleGeocodingService` — lightweight Google Geocoding API implementation
  with `language` and `region` support (forward + reverse only, no
  autocomplete).
- `FallbackGeocodingService` — wraps a primary and fallback service; silently
  falls back on any primary failure (network, quota, bad key, etc.).
  Autocomplete is delegated exclusively to the primary (no Photon fallback).
- `PlacePrediction` — lightweight model for Places API autocomplete results
  (`placeId`, `mainText`, `secondaryText`, `fullText`).
- `AddressPickerConfig.googleMapsApiKey` (`String?`) — convenience parameter;
  when set, uses `GooglePlacesService` as the primary provider with automatic
  Photon fallback. No key → Photon-only (default, free).
- `AddressPickerConfig.geocodingService` (`GeocodingService?`) — inject a
  fully custom geocoding service. Takes precedence over `googleMapsApiKey`
  when both are provided.
- `AddressPickerConfig.createGeocodingService()` — resolves the effective
  service from the configuration (custom → Google Places+fallback → Photon).
- `GeocodingResult.fromGoogleResult()` factory constructor for parsing
  Google Geocoding API responses.
- Barrel exports for `GeocodingService`, `GooglePlacesService`,
  `GoogleGeocodingService`, `FallbackGeocodingService`, `PhotonService`,
  and `PlacePrediction`.

### Changed
- `PhotonService` now implements `GeocodingService`.
- Hooks (`useAddressSearch`, `useReverseGeocode`) accept a `GeocodingService`
  parameter — callers (screens) manage the service lifecycle.
- Comprehensive error handling across all service, hook, and screen layers
  with consistent `debugPrint('[AddressPicker] ...')` diagnostic logging and
  stack-trace capture.
- User-facing error messages now show friendly text instead of raw exception
  strings.
- `SearchScreen` body wrapped in `SafeArea(top: false)` to prevent content
  from scrolling behind system navigation bars.
- `MapConfirmScreen` now renders reverse-geocode errors inline beneath the
  address card.
- Example app now includes an interactive **Google Maps API Key** text field
  in the configuration knobs section, with a helper label showing the active
  geocoding strategy.

### Fixed
- Content scrolling behind system bottom navigation bar on `SearchScreen`.
- Dead try/catch in `GoogleGeocodingService.search()` where the HTTP call
  was outside the try body, leaving the catch block unreachable.
- Silent error swallowing in `PhotonService` (`catch (_)`) — errors are now
  logged before returning fallback values.

### Breaking
- `GeocodingResult.placeId` type changed from `int` to `String` to
  accommodate Google's opaque `place_id` values (safe pre-1.0).
- Removed `usePhotonSearch` hook — replaced by the provider-agnostic
  `useAddressSearch`.

## 0.0.5

### Added
- `AddressAttribute` enum covering every captured field on a confirmed
  `StructuredAddress` (`displayName`, `street`, `houseNumber`, `city`,
  `state`, `postalCode`, `country`, `countryCode`, `latitude`, `longitude`,
  `primaryLine`, `secondaryLine`), plus an `AddressAttributeReader` extension
  (`readAttribute(AddressAttribute)`) to extract values as strings.
- `AddressFieldSpec.prefillFrom` (`AddressAttribute?`) — when set, the detail
  sheet pre-populates that field from the matching attribute of the confirmed
  address before the user edits it.
- `AddressFieldSpec.postalCode` preset now pre-fills from
  `AddressAttribute.postalCode` by default.

### Changed
- Example app demonstrates `prefillFrom` on Street and City custom fields.

## 0.0.4

### Added
- "Locate Me" button on the map confirm screen — fetches the current location,
  drops the pin, and recenters the map (with loading + error states).
- `MapConfirmScreen.initialLatLng` — lets the picker open the map directly at a
  given coordinate (used by the new current-location flow).
- Demo section in the README with an embedded preview video.
- `AddressPickerConfig.mapDarkMode` (`MapDarkMode.auto` / `.light` / `.dark`) —
  applies a `ColorFilter` invert+hue-rotate on the tile layer for dark-map
  emulation; `auto` follows `Theme.of(context).brightness`.
- `AddressPickerConfig.pinBuilder` — `WidgetBuilder?` to swap in any custom
  widget as the map marker without subclassing the screen.
- `AddressPickerConfig.confirmButtonStyle` — `ButtonStyle?` for full control
  over the "Confirm Address" button style.
- `AddressPickerConfig.attributionStyle` — declarative `AddressPickerAttribution`
  configuration (text, URI, background color, text style, alignment). Renders
  `© OpenStreetMap contributors` by default to comply with OSM tile usage
  policy. Set to `null` to suppress attribution entirely.
- `MapAttributionAlignment` enum (`bottomLeft` / `bottomRight`) for positioning
  the attribution chip.
- `AddressPickerAttribution.osm` — static const for the canonical OSM
  attribution, ready to use or extend.

### Changed
- **Breaking:** `SearchScreen.onCurrentLocation` now receives a `LatLng` instead
  of a `StructuredAddress`. Tapping "Use current location" from search now opens
  the map confirm step at the resolved coordinates rather than returning a
  result immediately.
- Disabled flutter_map 8.x's default on-disk tile cache so the package works
  without consumers wiring up `path_provider` (avoids `MissingPluginException`
  for `getApplicationCacheDirectory`).
- Map confirm screen body is now wrapped in `SafeArea`.
- Confirm button default style now derives from `sheetAccentColor ??
  colorScheme.primary` (previously hardcoded black). Fully overridable via the
  new `confirmButtonStyle` field.
- `MapPin` default color now resolves from `colorScheme.primary` instead of
  hardcoded black; explicit `color` parameter still takes priority.
- Example app home page is now scrollable (`SingleChildScrollView`) and includes
  interactive knobs for all four new configuration fields.

### Fixed
- Removed stale `jni` entry from generated Linux/Windows plugin lists.

## 0.0.3

### Changed
- Updated `pubspec.yaml` metadata for the `0.0.3` release.
  - Package version bumped to `0.0.3`.
  - Updated `homepage` URL and added `documentation` metadata.

## 0.0.2

### Added
- Redesigned address detail step as a **frosted-glass bottom sheet** presented
  over the confirmed map (blur, drag handle, hero address chip, glowing save
  button, subtle entrance animation). Built with ForUI + Flutter built-ins —
  no new dependencies.
- `AddressFieldSpec` — compose arbitrary detail fields with per-field `icon`,
  `required`, `validator`, `keyboardType`, `maxLines`, `maxLength`, and
  `quickFills` chips. Built-in presets: `AddressFieldSpec.apt`, `.floor`,
  `.deliveryNotes`.
- New sheet config on `AddressPickerConfig`: `detailSheetTitle`,
  `detailSheetSubtitle`, `saveButtonLabel`, `sheetBlurSigma`,
  `sheetCornerRadius`, `sheetAccentColor`, `showDragHandle`,
  `sheetDismissible`, `sheetEnableDrag`.
- `AddressDetails.values` keyed map + `operator []` for reading custom fields.
- `AddressFieldSpec.postalCode` — opt-in built-in preset for capturing a postal /
  ZIP code (handy for international addresses; not in the default set).
- `localeAwareSearch` on `AddressPickerConfig` (default `true`) — auto-restricts
  search results to the device locale's country. `countryCodes` still takes
  priority when set; set to `false` for global, unfiltered search.

### Changed
- **Breaking:** `AddressPickerConfig.detailFields` is now
  `List<AddressFieldSpec>?` (was `List<AddressDetailField>?`).
- Dismissing the detail step now returns the user to the map (to re-confirm)
  instead of cancelling the whole picker.

### Deprecated
- `AddressDetailField` enum — use `AddressFieldSpec` instead. Call
  `field.toSpec()` to migrate. `AddressDetails.apt/.floor/.deliveryNotes` are
  now convenience getters over `values`.

### Fixed
- Black screen after saving an address (the detail step previously popped past
  the picker route, emptying the navigator).

## 0.0.1+1

- Initial release
- Search-first address picker with Nominatim geocoding
- Map confirmation with tap-to-drop pin
- Structured address output (street, city, state, postal, country, latLng)
- Address detail screen (apt, floor, delivery notes)
- Recent addresses with local persistence
- Current location support via geolocator
- ForUI component library integration
- Material theme auto-bridging
