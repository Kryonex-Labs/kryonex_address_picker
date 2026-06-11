/// An opinionated, search-first address picker for Flutter.
///
/// Built with ForUI components, flutter_map, and pluggable geocoding
/// (Photon by default, Google Geocoding API optional).
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
export 'src/models/address_attribute.dart';
export 'src/models/address_detail_field.dart';
export 'src/models/address_details.dart';
export 'src/models/address_field_spec.dart';
export 'src/models/geocoding_result.dart';
export 'src/models/place_prediction.dart';
export 'src/models/selected_address.dart';
export 'src/models/structured_address.dart';

// Configuration
export 'src/theme/picker_theme.dart'
    show
        AddressPickerConfig,
        AddressPickerAttribution,
        MapAttributionAlignment,
        MapDarkMode;

// Services (public for advanced usage / custom implementations)
export 'src/services/geocoding_service.dart';
export 'src/services/fallback_geocoding_service.dart';
export 'src/services/google_geocoding_service.dart';
export 'src/services/google_places_service.dart';
export 'src/services/photon_service.dart';
