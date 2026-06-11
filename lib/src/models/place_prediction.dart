/// A search suggestion returned by the Places API (New) autocomplete endpoint.
///
/// Contains only the text fields needed to display the suggestion in a list.
/// The [placeId] must be resolved via [GeocodingService.placeDetails] to obtain
/// full coordinates and structured address data before navigation.
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.fullText,
  });

  /// The Place ID that can be resolved to full address details.
  final String placeId;

  /// The primary display text, e.g. "Main Street 1".
  final String mainText;

  /// The secondary display text, e.g. "London, UK".
  final String secondaryText;

  /// The full suggestion text combining main and secondary text.
  final String fullText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacePrediction &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;

  @override
  String toString() => 'PlacePrediction($fullText)';
}
