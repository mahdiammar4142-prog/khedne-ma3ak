# Lebanon Places

A cross-platform (iOS & Android) app for discovering and recommending places in Lebanon: restaurants, hotels, pools, beaches, and more. Includes smart search, user accounts, group events with voting, a chatbot, place guide, and trip planning/booking.

## Features

- **Smart taxonomy search** – e.g. searching "burgers" shows restaurants and snack places; "pool" shows pools and beach clubs. Search terms map to multiple place categories.
- **User accounts** – Sign up / login (email & password). Profile with connections to other users.
- **Place recommendations** – Browse by category and region; view details, ratings, contact, and booking.
- **Group events** – Create events, add members, suggest places, and vote to pick a venue.
- **Chatbot** – In-app assistant for recommendations and tips.
- **Place guide** – Browse places by category (restaurants, cafes, hotels, pools, etc.).
- **Trip advising & booking** – Plan trips and access booking via place details (phone/website) or external links.

## Tech stack

- **Flutter** (Dart) – iOS and Android
- **State** – Riverpod
- **Routing** – go_router
- **Backend (to wire)** – Firebase (Auth, Firestore); optional Algolia for search

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, 3.2+)
- Android Studio / Xcode for emulators or devices
- (Later) Firebase project and config files

## Setup

1. **Clone and open**
   ```bash
   cd "c:\Users\user\Desktop\BAU\Software Engineering\FinalProject"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run**
   ```bash
   flutter run
   ```
   Choose an Android emulator, iOS simulator, or connected device.

4. **Google Maps (required for map features)**
   - Get an API key and add it to Android and iOS. See [docs/GOOGLE_MAPS_SETUP.md](docs/GOOGLE_MAPS_SETUP.md).

5. **Firebase (when ready)**
   - Create a project at [Firebase Console](https://console.firebase.google.com).
   - Add Android and iOS apps and download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) into the project.
   - Enable Authentication (Email/Password) and Firestore.
   - In `lib/main.dart`, uncomment and use `Firebase.initializeApp()`.

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── router/       # go_router config
│   ├── theme/        # App theme
│   └── taxonomy/     # Smart search taxonomy (keywords → categories)
├── features/
│   ├── auth/         # Login, register
│   ├── home/         # Home screen, quick actions
│   ├── places/       # Search, place list, place detail (taxonomy-aware)
│   ├── events/       # Group events, voting
│   ├── profile/      # User profile, connections
│   ├── chatbot/      # Recommendation chatbot
│   ├── guide/        # Category-based place guide
│   └── trips/        # Trip planning & booking entry
assets/
└── images/
```

## Smart taxonomy

Taxonomy lives in `lib/core/taxonomy/taxonomy_model.dart`. It maps:

- **Keywords** (e.g. "burger", "pool", "hotel") and **synonyms** to **place categories** (restaurant, snacks, cafe, hotel, pool, beach, etc.).

Search uses this so that:
- "burgers" → restaurants + snacks
- "pool" → pool (and related)
- "hotel" / "stay" / "resort" → hotel (and pool where relevant)

You can extend `Taxonomy.nodes` with more keywords and categories for Lebanon.

## Next steps

- Add Firebase Auth and Firestore; replace demo repositories with real API calls.
- Add a connections/friends feature (Firestore `users` and `connections`).
- Enrich places data (e.g. from CMS or admin panel) and optionally add Algolia for full-text search.
- Implement real booking flow or deep links to booking partners.
- Add push notifications for event updates and friend activity.

## License

Private / educational use.
