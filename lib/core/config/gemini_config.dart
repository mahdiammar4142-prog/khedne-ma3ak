/// Gemini API key for the chatbot. Get a free key at https://aistudio.google.com/apikey
/// Option 1: Paste your key below for quick dev (don't commit real keys!)
/// Option 2: Run with --dart-define=GEMINI_API_KEY=your_key
String get geminiApiKey {
  const fromEnv = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (fromEnv.isNotEmpty) return fromEnv;
  return kGeminiApiKey;
}

/// Paste your key here for local dev, or leave empty.
/// Don't commit real keys to a public repo.
const String kGeminiApiKey = '';
