# Khedne Ma3ak – Presentation Guide

For each task/feature: **What did you use**, **Why**, and **How**.

---

## 1. App Framework & Cross-Platform

**What:** Flutter (Dart)

**Why:**
- Single codebase for iOS, Android, Web, and Windows
- Fast development with hot reload
- Rich widget library and Material Design
- Strong ecosystem for mobile apps

**How:**
- `main.dart` initializes the app with `runApp(ProviderScope(child: LebanonPlacesApp()))`
- `MaterialApp.router` uses `go_router` for navigation
- One Flutter project compiles to multiple platforms

---

## 2. State Management

**What:** Riverpod

**Why:**
- Declarative, testable state
- No `BuildContext` needed for providers
- Handles async (FutureProvider, AsyncValue)
- Recommended by Flutter team

**How:**
- `ProviderScope` wraps the app in `main.dart`
- Providers like `placesRepositoryProvider`, `searchResultsProvider`, `placeDetailProvider` hold data
- Screens use `ref.watch(provider)` to listen and `ref.read(provider)` to trigger updates
- Example: `searchResultsProvider(query)` fetches places when the query changes

---

## 3. Navigation & Routing

**What:** go_router

**Why:**
- Declarative routing with path-based URLs
- Deep linking support (e.g. `/search/place/1`)
- Redirect logic for auth (gate vs home)
- Nested routes for place detail under search

**How:**
- `app_router.dart` defines routes: `/gate`, `/login`, `/register`, `/home`, `/search`, `/search/place/:id`, `/map`, `/chatbot`, `/guide`, `/events`, `/profile`, `/trips`
- `_redirect()` checks auth: if logged in or guest → allow; else → send to `/gate`
- `context.push('/search', extra: 'pool')` passes initial query
- `context.go('/home')` replaces the stack (e.g. after login)

---

## 4. Authentication

**What:** Firebase Authentication + SharedPreferences

**Why:**
- Firebase Auth: secure, scalable, no custom backend
- Email/password is simple and widely used
- SharedPreferences: lightweight local storage for guest flag

**How:**
- `AuthRepository` wraps `FirebaseAuth.instance`
- `signInWithEmailAndPassword()` and `createUserWithEmailAndPassword()` call Firebase
- `isGuest()` reads `SharedPreferences` for key `lebanon_places_guest`
- `setGuest(true)` saves the flag when user taps "Continue as guest"
- Redirect in router uses `_auth.currentUser` and `_auth.isGuest()` to decide where to send the user

---

## 5. User Profiles

**What:** Cloud Firestore + UserProfileRepository

**Why:**
- Firestore: real-time NoSQL database, scales automatically
- User profiles need more than Auth (display name, connections, saved places)
- Firestore rules restrict access: users can only read/write their own document

**How:**
- `UserProfileRepository` uses `FirebaseFirestore.instance.collection('users')`
- On registration: `createProfile(profile)` writes `users/{uid}` with displayName, email, photoUrl, createdAt, updatedAt
- `getProfile(userId)` reads the document
- `updateConnections()` and `updateSavedPlaces()` update arrays in the document

---

## 6. Places Data & Search

**What:** Taxonomy model + PlacesRepository (Demo + Firestore option)

**Why:**
- Taxonomy: maps natural language ("burgers", "pool") to categories without a search engine
- Demo repository: 26 in-memory places for development without a database
- Firestore option: production-ready cloud storage

**How:**
- `Taxonomy.categoriesForQuery(query)` in `taxonomy_model.dart` matches keywords and synonyms to `PlaceCategory` (restaurant, pool, hotel, etc.)
- `DemoPlacesRepository.search(query)` filters places by taxonomy categories + text match on name/description/tags
- `placesRepositoryProvider` returns `DemoPlacesRepository` (switch to `FirestorePlacesRepository` when using Firestore)
- `searchResultsProvider(query)` → `repo.search(query)` → UI shows list

---

## 7. Place Cards & List UI

**What:** Flutter widgets (PlaceCard, PlaceThumbnail) + PlaceModel

**Why:**
- Reusable card component for consistent UI
- Category-based colors and icons for quick recognition
- PlaceModel: single data structure for place (id, name, category, region, rating, etc.)

**How:**
- `PlaceCard` shows thumbnail, name, category, region, rating
- `_PlaceThumbnail`: uses `placeBackgroundImageUrl()` for image, or category icon + color fallback
- Tap → `context.push('/search/place/${place.id}')`
- `PlaceModel` is immutable with `id`, `name`, `category`, `region`, `rating`, `tags`, `bookable`, etc.

---

## 8. Place Detail Screen

**What:** PlaceDetailScreen + placeDetailProvider + PlaceMapWidget + url_launcher

**Why:**
- Users need full info before visiting or booking
- Map shows location; url_launcher opens phone/website for contact

**How:**
- `placeDetailProvider(placeId)` → `PlacesRepository.getById(id)`
- Screen shows name, description, category, region, rating, address
- `PlaceMapWidget` embeds `GoogleMap` with marker at place coordinates
- "Open in Google Maps" uses `url_launcher` to open maps app
- "Book / Plan trip" uses `url_launcher` for `tel:` or `https:` if phone/website exist

---

## 9. Google Maps

**What:** google_maps_flutter package

**Why:**
- Standard maps for Lebanon
- Markers for places, camera centered on Beirut
- Users can open in Google Maps app for directions

**How:**
- `PlacesMapScreen` and `PlaceMapWidget` use `GoogleMap` widget
- `LebanonMapConfig.cameraForPlace(lat, lng)` sets initial camera
- Markers: `Marker(markerId, position: LatLng(...), infoWindow)`
- API key configured in Android/iOS (see `GOOGLE_MAPS_SETUP.md`)

---

## 10. AI Chatbot

**What:** Google Gemini API + Firebase Cloud Functions (web) + google_generative_ai (mobile/desktop)

**Why:**
- Gemini: free tier, good for conversational AI
- Web CORS: browsers block direct API calls; Cloud Function acts as proxy
- Mobile/desktop: no CORS, so direct API call is fine

**How:**
- `AiChatService` checks `kIsWeb`: if web → `_sendViaFunction()`, else → `_sendDirect()`
- **Web:** `FirebaseFunctions.instance.httpsCallable('chatWithGemini').call({ message, sessionId })` → Function calls Gemini, returns `{ reply }`
- **Mobile/desktop:** `GenerativeModel(apiKey, systemInstruction).startChat().sendMessage(text)` → response.text
- API key: `gemini_config.dart` (or dart-define for production)
- Fallback: if AI fails, keyword-based replies (guide, burger, pool, hotel, trip)

---

## 11. Cloud Function (chatWithGemini)

**What:** Firebase Cloud Functions (Node.js) + @google/generative-ai

**Why:**
- Web browsers block cross-origin requests to Gemini
- Function runs on Google servers, calls Gemini, returns reply to client
- Keeps API key server-side (secure)

**How:**
- `functions/index.js`: `onCall` handler receives `{ message, sessionId }`
- Uses `GEMINI_API_KEY` from `functions/.env` or Firebase config
- `GoogleGenerativeAI(apiKey).getGenerativeModel({ model: 'gemini-1.5-flash', systemInstruction })`
- `chat.sendMessage(message)` → `response.text()` → return `{ reply: text }`
- In-memory `chatSessions` Map for conversation history (use Redis/DB for production)

---

## 12. Theme & Styling

**What:** AppTheme (Material 3) + custom colors

**Why:**
- Consistent look across all screens
- Teal primary (#00A651) for Lebanon/cedar feel
- Bright accents (orange, cyan, blue) for category cards
- Material 3 for modern components

**How:**
- `app_theme.dart` defines `ThemeData.light` and `ThemeData.dark`
- `ColorScheme.fromSeed(seedColor: primary)` for derived colors
- Custom `appBarTheme`, `cardTheme`, `inputDecorationTheme`, `chipTheme`
- Screens use `Theme.of(context)` and `Colors.grey.shadeXXX` for consistency

---

## 13. Home Screen Layout

**What:** CustomScrollView + SliverGrid + category cards + nav buttons

**Why:**
- 2×2 grid for quick access to main categories
- Top nav: Activity, Bookings, Profile
- Bottom nav: Taxi, Explore, Add Location
- Matches "kazderni-style" with bright colors and full-bleed images

**How:**
- `SliverToBoxAdapter` for header and nav sections
- `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)` for 2×2
- `_CategoryCard` with image, label, border color, `onTap` → `/search` with query
- `_NavButton` with icon, label, color, `onTap` → route

---

## 14. Events (Group Events & Voting)

**What:** EventsRepository (Demo) + EventModel + CreateEventScreen + EventDetailScreen

**Why:**
- Groups need to pick a venue together
- Voting on suggested places simplifies decision-making
- Demo repo for development; Firestore can replace it

**How:**
- `EventModel`: id, name, createdBy, date, memberIds, placeVotes, selectedPlaceId
- `DemoEventsRepository`: in-memory list, `create()`, `addVote()`, `setSelectedPlace()`
- `CreateEventScreen`: form for name, date, description, members
- `EventDetailScreen`: shows event, suggested places, voting UI
- `PlaceVote(placeId, userId)` stored in event

---

## 15. Guide Screen

**What:** GuideScreen + guidePlacesProvider + guideCategoryProvider

**Why:**
- Browse places by category without typing
- Complements search for discovery

**How:**
- `guideCategoryProvider`: StateProvider<PlaceCategory?> for selected category
- `guidePlacesProvider`: FutureProvider that calls `repo.search('', categories: [cat])` or all if null
- Same PlaceCard list as search

---

## 16. Trip Planning

**What:** TripPlanningScreen + url_launcher (placeholder)

**Why:**
- Future: plan trips, book stays
- Current: placeholder screen; place detail has "Book / Plan trip" with phone/website links

**How:**
- `TripPlanningScreen` is a placeholder UI
- `url_launcher` in place detail: `launchUrl(Uri.parse('tel:...'))` or `launchUrl(Uri.parse(website))`

---

## 17. Dependency Injection

**What:** Riverpod providers

**Why:**
- Single source for repositories and services
- Easy to swap implementations (Demo vs Firestore)
- Testable: can override providers in tests

**How:**
- `placesRepositoryProvider` → `DemoPlacesRepository()` (change to `FirestorePlacesRepository()` when ready)
- `AuthRepository()` created where needed (or could be a provider)
- `AiChatService()` created in ChatbotScreen (stateless, no provider needed for now)

---

## 18. Error Handling & Fallbacks

**What:** try/catch, fallback replies, errorBuilder

**Why:**
- App should not crash on network/auth errors
- Chatbot should still respond if Gemini fails
- Images should show placeholder if load fails

**How:**
- `main.dart`: `FlutterError.onError` prints to debug
- Chatbot: `aiReply ?? _fallbackReply(text)` when AI returns null
- `Image.network(..., errorBuilder: (_, __, ___) => Icon(...))` for failed images
- Auth: `on Exception catch (e)` shows error message in UI

---

## Quick Reference Table

| Task | What | Why | How |
|------|------|-----|-----|
| Framework | Flutter | Cross-platform, single codebase | main.dart, MaterialApp |
| State | Riverpod | Declarative, testable | Providers, ref.watch |
| Routing | go_router | Path-based, redirect | app_router.dart |
| Auth | Firebase Auth | No custom backend | AuthRepository |
| Guest mode | SharedPreferences | Local flag | setGuest, isGuest |
| Profiles | Firestore | Extra user data | UserProfileRepository |
| Places | Taxonomy + Repository | Smart search, flexible data | DemoPlacesRepository, Taxonomy |
| Maps | google_maps_flutter | Standard maps | GoogleMap, markers |
| Chatbot | Gemini + Cloud Function | AI + web CORS fix | AiChatService, functions/index.js |
| Theme | AppTheme | Consistency | app_theme.dart |
| Events | DemoEventsRepository | Group voting | EventModel, addVote |
