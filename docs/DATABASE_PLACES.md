# Places database (Firestore)

In production, all places should live in a **database**. This project supports:

1. **Demo (default)** – in-memory list in `DemoPlacesRepository` for development.
2. **Firestore** – cloud database via `FirestorePlacesRepository` when Firebase is set up.

## Firestore collection: `places`

Each document ID is the place ID. Field names match `PlaceModel`:

| Field       | Type     | Required | Description                |
|------------|----------|----------|----------------------------|
| name       | string   | yes      | Place name                 |
| description| string   | no       | Short description          |
| category   | string   | yes      | One of: restaurant, cafe, snacks, hotel, pool, beach, nightlife, nature, shopping, activity, other |
| region     | string   | no       | e.g. Beirut                |
| address    | string   | no       | Full address               |
| latitude   | number   | no       | For map                    |
| longitude  | number   | no       | For map                    |
| rating     | number   | no       | e.g. 4.5                   |
| imageUrls  | array    | no       | List of image URLs         |
| tags       | array    | no       | Search tags                |
| phone      | string   | no       |                            |
| website    | string   | no       |                            |
| bookable   | boolean  | no       | Default false              |

## How to use the database

### 1. Enable Firebase and Firestore

- Create a project in [Firebase Console](https://console.firebase.google.com).
- Add your app (Android / iOS / Web).
- Enable **Cloud Firestore** and create a database.

### 2. Switch the app to Firestore

In `lib/features/places/data/places_repository_provider.dart`:

- Import: `import 'package:lebanon_places/features/places/data/firestore_places_repository.dart';`
- In `main.dart`, call `await Firebase.initializeApp();` before `runApp`.
- Change the provider to use Firestore:

```dart
final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return FirestorePlacesRepository();
});
```

### 3. Seed places from the demo list

To copy the current 26 Beirut places into Firestore once:

- Use the **Firebase Console** → Firestore → **Import** (upload a JSON), or
- Run a one-off script (e.g. in a small Dart script or a temporary “Seed” button in the app):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lebanon_places/features/places/data/firestore_places_repository.dart';
import 'package:lebanon_places/features/places/data/places_repository.dart';

// After Firebase.initializeApp():
final repo = FirestorePlacesRepository();
await repo.seedPlaces(DemoPlacesRepository.allDemoPlaces);
```

After that, the app will read all places from Firestore. You can add or edit places in the Firebase Console or later via an admin screen.

## Security rules (Firestore)

**Required for registration and profiles.** The app writes user profiles to `users/{uid}`. Add these rules in **Firebase Console → Firestore → Rules** (or deploy `firestore.rules` with Firebase CLI):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /places/{placeId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

Without the `users` rule, registration shows "Missing or insufficient permissions" when creating the profile.
