/// Google Maps / Street View API key for place backgrounds.
/// Option 1: Set [kGoogleMapsApiKey] below for quick dev (same key as web/index.html).
/// Option 2: Build with --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
String? get googleMapsApiKey {
  const fromEnv = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  if (fromEnv.isNotEmpty) return fromEnv;
  return kGoogleMapsApiKey.isEmpty ? null : kGoogleMapsApiKey;
}

/// Paste your key here for place background images (Street View), or leave empty.
/// Same key as in web/index.html; enable "Street View Static API" in Google Cloud.
const String kGoogleMapsApiKey = '';
