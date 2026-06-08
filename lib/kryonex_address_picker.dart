/// An opinionated, search-first address picker for Flutter.
///
/// Built with ForUI components, flutter_map, and Photon geocoding.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:kryonex_address_picker/kryonex_address_picker.dart';
///
/// final result = await showAddressPicker(context);
/// if (result != null) {
///   print(result.address.displayName);
///   print(result.address.city);
///   print(result.details?.apt);
/// }
/// ```
library;

// Entry point
export 'src/address_picker.dart' show showAddressPicker;

// Models
export 'src/models/address_detail_field.dart';
export 'src/models/address_details.dart';
export 'src/models/address_field_spec.dart';
export 'src/models/geocoding_result.dart';
export 'src/models/selected_address.dart';
export 'src/models/structured_address.dart';

// Configuration
export 'src/theme/picker_theme.dart'
    show
        AddressPickerConfig,
        AddressPickerAttribution,
        MapAttributionAlignment,
        MapDarkMode;
