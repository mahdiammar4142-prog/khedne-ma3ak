import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps configuration for Lebanon.
/// Set your API key in Android (AndroidManifest.xml) and iOS (AppDelegate).
class LebanonMapConfig {
  LebanonMapConfig._();

  /// Default map center: Beirut, Lebanon.
  static const LatLng defaultCenter = LatLng(33.8938, 35.5018);
  static const double minLat = 33.05;
  static const double maxLat = 34.70;
  static const double minLng = 35.05;
  static const double maxLng = 36.65;

  /// Zoom level for country view (~Lebanon).
  static const double zoomCountry = 8.5;

  /// Zoom level for city (Beirut area).
  static const double zoomCity = 12.0;

  /// Zoom level for single place.
  static const double zoomPlace = 16.0;

  /// Default camera position for Lebanon.
  static const CameraPosition defaultCamera = CameraPosition(
    target: defaultCenter,
    zoom: zoomCity,
  );

  /// Camera for a single place (lat, lng).
  static CameraPosition cameraForPlace(double lat, double lng) {
    return CameraPosition(
      target: LatLng(lat, lng),
      zoom: zoomPlace,
    );
  }

  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static bool isLikelyInLebanon(double? lat, double? lng) {
    if (!isValidCoordinate(lat, lng)) return false;
    return lat! >= minLat && lat <= maxLat && lng! >= minLng && lng <= maxLng;
  }
}
