# Connect to AppLebanon Firebase Project

## 1. Link your app to AppLebanon

Run in the project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select your **AppLebanon** project when prompted. This updates `lib/firebase_options.dart` and `.firebaserc`.

## 2. Deploy Firestore rules

In Firebase Console → **Firestore Database** → **Rules**, paste:

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

Click **Publish**.

Or use Firebase CLI:

```bash
firebase use YOUR_PROJECT_ID   # from Firebase Console → Project settings
firebase deploy --only firestore:rules
```

## 3. Enable Firestore

In Firebase Console → **Firestore Database** → **Create database** (if not done yet). Choose a location and start in **test mode** or **production mode** (the rules above will apply once deployed).
