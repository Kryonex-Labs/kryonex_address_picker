import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../models/address_detail_field.dart';

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

  /// Whether to show the address detail screen (apt, floor, notes).
  /// Default: true.
  final bool showDetailScreen;

  /// Which detail fields to show. Default: all fields.
  /// Order determines display order.
  final List<AddressDetailField>? detailFields;

  /// Placeholder text for the search bar.
  final String? searchHint;

  /// Default zoom level when centering the map on an address.
  final double mapZoom;

  /// The detail fields to display, defaulting to all if not specified.
  List<AddressDetailField> get effectiveDetailFields =>
      detailFields ?? AddressDetailField.values;
}
