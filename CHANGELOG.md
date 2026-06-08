# Changelog

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
