import 'package:lebanon_places/core/config/google_api_config.dart';
import 'package:lebanon_places/features/places/domain/place_model.dart';

/// Builds the best background image URL for a place: [imageUrls] first, else Google Street View at lat/lng.
String? placeBackgroundImageUrl(PlaceModel place) {
  if (place.imageUrls.isNotEmpty) return place.imageUrls.first;
  final key = googleMapsApiKey;
  if (place.hasLocation && key != null && key.isNotEmpty) {
    final lat = place.latitude!;
    final lng = place.longitude!;
    return 'https://maps.googleapis.com/maps/api/streetview?size=600x400&location=$lat,$lng&key=$key';
  }
  return null;
}
