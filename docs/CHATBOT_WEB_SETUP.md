# Chatbot on Web – Firebase Functions Setup

On **Flutter web**, the browser blocks direct calls to the Gemini API (CORS). The app uses a **Firebase Cloud Function** as a proxy instead.

## 1. Install and deploy the Cloud Function

```bash
cd functions
npm install
cd ..
```

Create `functions/.env` (copy from `functions/.env.example`):

```
GEMINI_API_KEY=your_key_here
```

**Important:** For production deployment, `.env` is not uploaded. You must set the variable in Firebase:

1. Open [Firebase Console](https://console.firebase.google.com/) → your project
2. Go to **Functions** → **Environment variables** (or use the function's configuration)
3. Add: `GEMINI_API_KEY` = your key

Then deploy:

```bash
firebase deploy --only functions
```

## 2. Run the app

```bash
flutter run -d chrome
```

The chatbot will call the Cloud Function, which calls Gemini. No CORS issues.

## Mobile / desktop

On Android, iOS, or desktop, the app calls the Gemini API directly (no Cloud Function). Add your key in `lib/core/config/gemini_config.dart`.
