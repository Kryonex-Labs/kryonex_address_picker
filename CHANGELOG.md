# Changelog

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
