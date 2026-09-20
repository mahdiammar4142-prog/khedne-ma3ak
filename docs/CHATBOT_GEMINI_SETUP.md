# Chatbot – Gemini AI Setup

The chatbot uses **Google Gemini** (free tier). No backend required.

## 1. Get a free API key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **Create API key**
4. Copy the key

## 2. Add the key to the app

**Option A – Paste in code (quick dev)**

Edit `lib/core/config/gemini_config.dart`:

```dart
const String kGeminiApiKey = 'YOUR_KEY_HERE';
```

**Option B – Dart define (recommended for production)**

Run the app with:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Or for web:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key_here
```

## 3. Fallback behavior

If no API key is set, the chatbot uses built-in keyword replies (guide, burgers, pool, hotel, trip).

## Security

- Do **not** commit real API keys to git
- For production, use a backend (e.g. Firebase Functions) to call Gemini and keep the key server-side
