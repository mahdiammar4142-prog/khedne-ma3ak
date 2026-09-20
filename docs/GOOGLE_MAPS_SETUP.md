# Google Maps API setup for Lebanon

The app uses **Google Maps** for all places in Lebanon. You need a **Google Maps API key** and to add it to both Android and iOS.

## 1. Get an API key

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project.
3. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Street View Static API** (for place background images in list and detail)
4. Go to **Credentials** → **Create credentials** → **API key**.
5. (Recommended) Restrict the key to your app’s package name (Android), bundle ID (iOS), or HTTP referrers (Web).

## 2. Web (Chrome / running in browser)

1. Enable **Maps JavaScript API** in Google Cloud Console (in addition to or instead of Android/iOS if you only run on web).
2. Open `web/index.html` in the project.
3. Find the line with `YOUR_GOOGLE_MAPS_API_KEY` and replace it with your actual API key:
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_KEY"></script>
   ```
   Without this, the Map screen will show an error when you run with `flutter run -d chrome`.

   **Place background images:** To show Google Street View photos for each place (when the place has no custom image), set your key in `lib/core/config/google_api_config.dart`: assign it to `kGoogleMapsApiKey`. The same key works if the Street View Static API is enabled.

## 3. Android

1. Open `android/app/src/main/AndroidManifest.xml`.
2. Add the key inside `<application>`:

```xml
<application ...>
    <!-- ... existing content ... -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_ANDROID_API_KEY"/>
</application>
```

Replace `YOUR_ANDROID_API_KEY` with your key.

## 4. iOS

1. Open `ios/Runner/AppDelegate.swift` (or `AppDelegate.m`).
2. Import and set the key **before** `GeneratedPluginRegistrant.register`:

**AppDelegate.swift:**

```swift
import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

Replace `YOUR_IOS_API_KEY` with your key.

**If you use Objective-C (AppDelegate.m):**

```objc
#import "GoogleMaps/GoogleMaps.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GMSServices provideAPIKey:@"YOUR_IOS_API_KEY"];
  // ... rest
}
```

## 5. Create platform folders (if needed)

If you don’t have `android/` and `ios/` yet, run from the project root:

```bash
flutter create . --org com.lebanonplaces --project-name lebanon_places
```

Then add the API key as above.

## What the app uses

- **All places** have `latitude` and `longitude` (Lebanon coordinates).
- **Places map screen** (`/map`): full map of Lebanon with markers; optional search query to filter.
- **Place detail**: embedded map + “Open in Google Maps” link.
- **Default center**: Beirut (33.8938, 35.5018).
