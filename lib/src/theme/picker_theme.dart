import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../models/address_field_spec.dart';

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

  /// The detail fields to display, defaulting to the built-in set if not
  /// specified.
  List<AddressFieldSpec> get effectiveDetailFields =>
      detailFields ?? AddressFieldSpec.defaults;
}
