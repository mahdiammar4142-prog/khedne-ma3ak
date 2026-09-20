# Khedne Ma3ak – Project Report

**Course:** Software Engineering  
**Project:** Lebanon Places (Khedne Ma3ak)  
**Version:** 1.0.0  

---

## 1. Project Overview

**Khedne Ma3ak** (خدني معك – “Take me with you”) is a cross-platform mobile and web application for discovering and recommending places in Lebanon. The app helps users find restaurants, hotels, pools, beaches, sports activities, and more through smart search, category browsing, and an AI-powered chatbot.

### Key Features Implemented

| Feature | Description |
|--------|-------------|
| **Smart taxonomy search** | Search terms (e.g. "burgers", "pool", "hotel") map to multiple place categories via a configurable taxonomy |
| **User accounts** | Sign up, login (email & password), and profile management via Firebase Auth |
| **Place recommendations** | Browse by category and region; view details, ratings, contact info, and booking links |
| **Group events** | Create events, add members, suggest places, and vote to pick a venue |
| **AI chatbot** | In-app assistant powered by Google Gemini for recommendations and travel tips |
| **Place guide** | Category-based browsing (restaurants, cafes, hotels, pools, beaches, etc.) |
| **Trip planning & booking** | Plan trips and access booking via place details (phone/website) or external links |
| **Google Maps** | Map view of places in Lebanon with location markers |

### Tech Stack

- **Frontend:** Flutter (Dart) – iOS, Android, Web, Windows
- **State management:** Riverpod
- **Routing:** go_router
- **Backend:** Firebase (Auth, Firestore, Cloud Functions)
- **Maps:** Google Maps Flutter
- **AI:** Google Gemini (free tier) via `google_generative_ai` and Firebase Cloud Functions

---

## 2. Objectives

1. **Discoverability** – Help users find places in Lebanon by category, keyword, and location
2. **User engagement** – Enable accounts, profiles, and social features (events, voting)
3. **Intelligent assistance** – Provide an AI chatbot for recommendations and travel advice
4. **Cross-platform reach** – Support mobile (iOS/Android), web, and desktop (Windows)
5. **Scalability** – Use cloud services (Firebase) for auth, data, and serverless functions

---

## 3. Background

Lebanon has a rich tourism and hospitality sector, but information about places is often scattered across social media, word of mouth, and various websites. **Khedne Ma3ak** centralizes this information in a single app with:

- A **smart taxonomy** that understands Lebanese context (e.g. mezze, shawarma, pool day, beach club)
- **Firebase** for authentication and data storage, enabling real-time updates and user-generated content
- **Google Gemini** for conversational AI, offering personalized recommendations without requiring a custom NLP backend

The project follows a feature-based architecture (auth, home, places, events, profile, chatbot, guide, trips) with clear separation between data, domain, and presentation layers.

---

## 4. Literature Review

### Relevant Technologies and Approaches

| Topic | Source / Reference | Relevance |
|-------|--------------------|-----------|
| **Flutter cross-platform development** | [Flutter documentation](https://docs.flutter.dev) | Single codebase for mobile, web, and desktop |
| **Firebase BaaS** | [Firebase documentation](https://firebase.google.com/docs) | Auth, Firestore, Cloud Functions for backend |
| **Riverpod state management** | [Riverpod package](https://riverpod.dev) | Declarative, testable state for Flutter |
| **Google Gemini API** | [Google AI Studio](https://aistudio.google.com) | Free-tier generative AI for chatbot |
| **Taxonomy-based search** | Custom implementation in `lib/core/taxonomy/` | Keyword-to-category mapping for Lebanon-specific search |
| **CORS and web APIs** | [MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) | Rationale for Cloud Function proxy on web |

### Design Patterns Used

- **Repository pattern** – `PlacesRepository`, `AuthRepository`, `EventsRepository` abstract data sources (demo vs Firestore)
- **Provider pattern** – Riverpod providers for dependency injection and state
- **Feature-based structure** – Each feature (auth, places, chatbot, etc.) has its own `data`, `domain`, and `presentation` folders

---

## 5. Applications

### Target Users

- **Tourists** – Visitors to Lebanon looking for restaurants, hotels, and activities
- **Locals** – Residents seeking new places (pools, beaches, cafes, nightlife)
- **Groups** – Friends or families planning outings with event creation and voting

### Use Cases

1. **Search** – User types "burgers" → app shows restaurants and snack places
2. **Browse** – User selects "Pools and Beaches" from home → sees category guide
3. **Chat** – User asks "Where can I find a good pool in Jounieh?" → AI suggests places
4. **Events** – User creates event, adds friends, suggests places, votes on venue
5. **Booking** – User views place detail → taps phone/website to contact or book

### Platforms

- **Android / iOS** – Native mobile experience
- **Web** – Browser-based (Chrome, etc.) with Cloud Function for chatbot CORS
- **Windows** – Desktop (requires Visual Studio toolchain for build)

---

## 6. Alternative Designs

### Considered Alternatives

| Aspect | Chosen Approach | Alternative |
|--------|-----------------|-------------|
| **Backend** | Firebase (Auth, Firestore, Functions) | Custom REST API, Supabase, AWS Amplify |
| **AI chatbot** | Google Gemini (free tier) | OpenAI GPT, custom rule-based bot, Dialogflow |
| **Web chatbot** | Firebase Cloud Function proxy | Direct Gemini call (blocked by CORS in browser) |
| **Search** | Taxonomy-based keyword mapping | Algolia full-text search, Elasticsearch |
| **State** | Riverpod | Provider, Bloc, GetX |
| **Routing** | go_router | Navigator 2.0 manual, auto_route |

### Rationale for Choices

- **Firebase** – Quick setup, scalable, integrates well with Flutter
- **Gemini** – Free tier sufficient for MVP; Cloud Function needed only for web
- **Taxonomy** – Lightweight, no external search service; extensible for Lebanon-specific terms
- **Riverpod + go_router** – Modern, declarative, recommended by Flutter team

---

## 7. Constraints

### Technical Constraints

- **Web CORS** – Browsers block direct Gemini API calls; Cloud Function proxy required for web
- **Firebase Blaze plan** – Cloud Functions deployment requires upgrade from Spark (free) to Blaze
- **Visual Studio** – Windows desktop build requires Visual Studio with C++ workload
- **API keys** – Gemini API key must be kept secure; on web, must be server-side (Cloud Function)

### Project Constraints

- **Educational use** – Private/educational license; not for commercial distribution
- **Demo data** – Places can use in-memory demo or Firestore; no external CMS yet
- **Booking** – Placeholder; real booking flows or deep links to partners to be added later

### Dependencies

- Flutter SDK 3.2+
- Firebase project (Auth, Firestore, optionally Functions)
- Google Maps API key
- Gemini API key (from Google AI Studio)

---

## 8. Project Issues

### Resolved Issues

| Issue | Resolution |
|-------|------------|
| **firebase_core vs cloud_functions conflict** | Upgraded `cloud_functions` from `^4.6.0` to `^5.6.2` for compatibility with `firebase_core ^3.14.0` |
| **Web chatbot CORS** | Implemented Firebase Cloud Function `chatWithGemini` as proxy; app uses Function on web, direct API on mobile/desktop |
| **UI consistency** | Applied unified theme (white background, teal primary, grey text) across all screens |

### Open Issues

| Issue | Status | Notes |
|-------|--------|-------|
| **Cloud Function not deployed** | Pending | Requires Firebase Blaze plan; web chatbot falls back to keyword replies until deployed |
| **Windows build fails** | Environment | "Unable to find suitable Visual Studio toolchain" – user must install Visual Studio with C++ workload |
| **Flutter not in PATH** | Environment | Some terminals do not have Flutter in PATH; use IDE terminal or full path |
| **Real booking flow** | Future | Currently placeholder; integrate real booking or partner deep links |

### Known Limitations

- Chatbot on web uses fallback keyword replies if Cloud Function is not deployed
- Session storage for chatbot is in-memory (use Redis/DB for production scale)
- No push notifications for event updates yet

---

## 9. Team Members & Tasks

*Update this section with your actual team structure and assignments.*

### Suggested Task Distribution (7 members)

| # | Member | Area | Files / Responsibilities |
|---|--------|------|---------------------------|
| 1 | *[Name]* | **Auth & Profile** | `lib/features/auth/`, `lib/features/profile/`, gate/login/register screens |
| 2 | *[Name]* | **Home & Navigation** | `lib/features/home/`, `lib/core/router/`, `lib/core/theme/` |
| 3 | *[Name]* | **Places & Search** | `lib/features/places/`, `lib/core/taxonomy/`, search, map, place detail |
| 4 | *[Name]* | **Guide & Categories** | `lib/features/guide/`, category browsing, place cards |
| 5 | *[Name]* | **Events** | `lib/features/events/`, create event, voting, event detail |
| 6 | *[Name]* | **Chatbot & AI** | `lib/features/chatbot/`, `lib/core/config/gemini_config.dart`, `functions/` |
| 7 | *[Name]* | **Trips & Firebase** | `lib/features/trips/`, Firebase setup, Firestore, Cloud Functions deployment |

### File Mapping (Reference)

```
lib/
├── main.dart
├── core/
│   ├── config/          # Gemini API config
│   ├── router/          # go_router, routes
│   ├── theme/           # App theme
│   └── taxonomy/        # Search taxonomy
├── features/
│   ├── auth/            # Gate, login, register, auth repo
│   ├── home/            # Home screen, category grid
│   ├── places/          # Search, list, detail, map, Firestore repo
│   ├── events/          # Create event, event detail, voting
│   ├── profile/         # Profile screen
│   ├── chatbot/         # Chatbot screen, AI service
│   ├── guide/           # Category guide
│   └── trips/           # Trip planning
functions/
└── index.js             # chatWithGemini Cloud Function
```

---

## Appendix: Setup Commands

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on Chrome (web)
flutter run -d chrome

# Run on Windows (requires Visual Studio)
flutter run -d windows

# Deploy Cloud Function (requires Blaze plan)
cd functions && npm install && cd ..
firebase deploy --only functions
```

---

*Report generated from project documentation and codebase. Update team names and task assignments as needed.*
