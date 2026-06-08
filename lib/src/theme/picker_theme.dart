import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../models/address_field_spec.dart';

/// Controls how the map tiles emulate dark mode via a [ColorFilter].
enum MapDarkMode {
  /// Follow the ambient [ThemeData.brightness] (default).
  auto,

  /// Force light tiles — no filter applied.
  light,

  /// Force dark tiles — invert + hue-rotate filter applied.
  dark,
}

/// Declarative configuration for the map attribution widget.
///
/// Pass `null` as [AddressPickerConfig.attributionStyle] to disable
/// attribution entirely. The default factory [AddressPickerAttribution.osmDefault]
/// renders the required OpenStreetMap attribution to comply with OSM tile
/// usage policy.
class AddressPickerAttribution {
  const AddressPickerAttribution({
    required this.text,
    this.uri,
    this.backgroundColor,
    this.textStyle,
    this.alignment = MapAttributionAlignment.bottomRight,
  });

  /// Standard OpenStreetMap attribution, required by OSM tile usage policy.
  static const AddressPickerAttribution osm = AddressPickerAttribution(
    text: '© OpenStreetMap contributors',
    uri: 'https://openstreetmap.org/copyright',
  );

  /// Attribution label shown on the map.
  final String text;

  /// Optional URL opened when the user taps the attribution.
  final String? uri;

  /// Background color of the attribution chip.
  final Color? backgroundColor;

  /// Text style for the attribution label.
  final TextStyle? textStyle;

  /// Where to anchor the attribution widget on the map.
  final MapAttributionAlignment alignment;
}

/// Alignment options for [AddressPickerAttribution].
enum MapAttributionAlignment { bottomLeft, bottomRight }

/// Configuration for the address picker.
///
/// All fields are optional — sensible defaults are applied. Pass
/// this to [showAddressPicker] to customize behavior.
class AddressPickerConfig {
  const AddressPickerConfig({
    this.theme,
    this.materialTheme,
    this.initialLocation,
    this.countryCodes,
    this.localeAwareSearch = true,
    this.maxRecentAddresses = 5,
    this.showDetailScreen = true,
    this.detailFields,
    this.searchHint,
    this.mapZoom = 16.0,
    this.detailSheetTitle = 'Add details',
    this.detailSheetSubtitle,
    this.saveButtonLabel = 'Save address',
    this.sheetBlurSigma = 18.0,
    this.sheetCornerRadius = 28.0,
    this.sheetAccentColor,
    this.showDragHandle = true,
    this.sheetDismissible = true,
    this.sheetEnableDrag = true,
    this.mapDarkMode = MapDarkMode.auto,
    this.pinBuilder,
    this.confirmButtonStyle,
    this.attributionStyle = AddressPickerAttribution.osm,
  });

  /// Explicit ForUI theme. Takes highest priority.
  final FThemeData? theme;

  /// Material theme to auto-bridge to ForUI. Used when [theme] is null.
  final ThemeData? materialTheme;

  /// Initial map center. Defaults to (0, 0) if not provided.
  final LatLng? initialLocation;

  /// ISO 3166-1 alpha-2 country codes to filter Nominatim results.
  /// Example: `['us', 'ca']` for US and Canada only.
  /// When set, this takes priority over [localeAwareSearch].
  final List<String>? countryCodes;

  /// When `true` (default), the device locale is used to automatically
  /// restrict search results to the user's country.
  ///
  /// Priority order:
  /// 1. [countryCodes] — explicit codes always win.
  /// 2. [localeAwareSearch] `true` — auto-detect from device locale.
  /// 3. [localeAwareSearch] `false` — global, no country filter.
  final bool localeAwareSearch;

  /// Maximum number of recent addresses to display. Default: 5.
  final int maxRecentAddresses;

  /// Whether to show the address detail sheet (apt, floor, notes).
  /// Default: true.
  final bool showDetailScreen;

  /// Which detail fields to show, and in what order.
  ///
  /// Compose [AddressFieldSpec] presets ([AddressFieldSpec.apt],
  /// [AddressFieldSpec.floor], [AddressFieldSpec.deliveryNotes]) with your own
  /// custom fields. Defaults to all three built-in fields.
  final List<AddressFieldSpec>? detailFields;

  /// Placeholder text for the search bar.
  final String? searchHint;

  /// Default zoom level when centering the map on an address.
  final double mapZoom;

  /// Title shown at the top of the detail sheet. Default: 'Add details'.
  final String detailSheetTitle;

  /// Optional subtitle shown beneath [detailSheetTitle].
  final String? detailSheetSubtitle;

  /// Label for the sheet's primary save button. Default: 'Save address'.
  final String saveButtonLabel;

  /// Gaussian blur sigma applied behind the frosted-glass sheet. Default: 18.
  final double sheetBlurSigma;

  /// Corner radius of the sheet's top edge. Default: 28.
  final double sheetCornerRadius;

  /// Accent colour for the save button's glow. Defaults to the theme primary.
  final Color? sheetAccentColor;

  /// Whether to show the drag handle at the top of the sheet. Default: true.
  final bool showDragHandle;

  /// Whether tapping the scrim dismisses the sheet. Default: true.
  final bool sheetDismissible;

  /// Whether the sheet can be dragged down to dismiss. Default: true.
  final bool sheetEnableDrag;

  /// Controls tile dark-mode emulation. [MapDarkMode.auto] (default) follows
  /// the ambient [ThemeData.brightness].
  final MapDarkMode mapDarkMode;

  /// Custom map pin widget builder. When null, a default [MapPin] is rendered
  /// using [ColorScheme.primary] as its color.
  final WidgetBuilder? pinBuilder;

  /// Style applied to the Confirm Address button.
  ///
  /// When null, a default style is derived from [sheetAccentColor] ??
  /// [ColorScheme.primary].
  final ButtonStyle? confirmButtonStyle;

  /// Attribution widget configuration. Defaults to [AddressPickerAttribution.osm]
  /// (required by OSM tile usage policy). Set to `null` to suppress attribution.
  final AddressPickerAttribution? attributionStyle;

  /// The detail fields to display, defaulting to the built-in set if not
  /// specified.
  List<AddressFieldSpec> get effectiveDetailFields =>
      detailFields ?? AddressFieldSpec.defaults;
}
