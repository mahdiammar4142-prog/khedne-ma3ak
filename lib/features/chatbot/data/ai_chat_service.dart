import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lebanon_places/core/config/gemini_config.dart';

/// AI chat service using Google Gemini (free tier).
/// On web: uses Firebase Cloud Function to avoid CORS.
/// On mobile/desktop: calls Gemini API directly.
enum AiReplySource {
  geminiDirect,
  geminiFunction,
  unavailable,
  error,
}

class AiChatResult {
  final String? reply;
  final AiReplySource source;
  final String? error;

  const AiChatResult({
    required this.reply,
    required this.source,
    this.error,
  });

  bool get isSuccess => reply != null && reply!.trim().isNotEmpty;
}

class AiChatService {
  AiChatService() {
    _apiKey = geminiApiKey;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  late final String _apiKey;
  late String _sessionId;
  static const List<String> _candidateModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-1.5-flash-latest',
  ];
  int _activeModelIndex = 0;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  bool get isAvailable => kIsWeb ? true : _apiKey.isNotEmpty;
  String get modeLabel => kIsWeb
      ? 'Gemini via Firebase Function'
      : 'Direct Gemini API (${_candidateModels[_activeModelIndex]})';

  static const _systemInstruction = '''
You are a friendly, knowledgeable AI travel assistant for Khedne Ma3ak, an app that helps users discover places in Lebanon.

Your role:
- Answer questions about restaurants, hotels, pools, beaches, and activities in Lebanon
- Give natural, conversational replies – not robotic or template-like
- Mention real Lebanese cities and areas (Beirut, Byblos, Jounieh, Batroun, etc.) when relevant
- Suggest using the app's Search and Guide when users want to browse places
- Keep responses concise (2–4 sentences) but warm and helpful

Be personable and engaging. Vary your phrasing. Show personality.
''';

  GenerativeModel get _generativeModel {
    _model ??= GenerativeModel(
      model: _candidateModels[_activeModelIndex],
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 1024,
      ),
    );
    return _model!;
  }

  ChatSession get _session {
    _chatSession ??= _generativeModel.startChat();
    return _chatSession!;
  }

  /// Sends a message to Gemini and returns the reply.
  /// Returns null if API is unavailable or request fails.
  Future<String?> sendMessage(String userMessage) async {
    final result = await sendMessageDetailed(userMessage);
    return result.reply;
  }

  Future<AiChatResult> sendMessageDetailed(String userMessage) async {
    if (kIsWeb) {
      return _sendViaFunction(userMessage);
    }
    return _sendDirect(userMessage);
  }

  Future<AiChatResult> _sendViaFunction(String userMessage) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('chatWithGemini');
      final result = await callable
          .call<Map<String, dynamic>>({
            'message': userMessage,
            'sessionId': _sessionId,
          })
          .timeout(const Duration(seconds: 15));
      final reply = result.data['reply'] as String?;
      if (reply == null || reply.trim().isEmpty) {
        return const AiChatResult(
          reply: null,
          source: AiReplySource.error,
          error: 'Function returned an empty reply.',
        );
      }
      return AiChatResult(reply: reply, source: AiReplySource.geminiFunction);
    } on TimeoutException {
      return const AiChatResult(
        reply: null,
        source: AiReplySource.error,
        error: 'Gemini request timed out.',
      );
    } on FirebaseFunctionsException catch (e, st) {
      if (kDebugMode) {
        debugPrint('Gemini (Function) error: ${e.code} ${e.message}');
        debugPrint('Stack: $st');
      }
      return AiChatResult(
        reply: null,
        source: AiReplySource.error,
        error: 'Function error (${e.code}): ${e.message ?? 'Unknown error'}',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Gemini (Function) error: $e');
        debugPrint('Stack: $st');
      }
      return AiChatResult(
        reply: null,
        source: AiReplySource.error,
        error: 'Unexpected error: $e',
      );
    }
  }

  Future<AiChatResult> _sendDirect(String userMessage, {int attempt = 0}) async {
    if (!_apiKey.isNotEmpty) {
      return const AiChatResult(
        reply: null,
        source: AiReplySource.unavailable,
        error: 'GEMINI_API_KEY is missing.',
      );
    }
    try {
      final response = await _session
          .sendMessage(
            Content.text(userMessage),
          )
          .timeout(const Duration(seconds: 20));
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        if (kDebugMode) debugPrint('Gemini: empty response');
        return const AiChatResult(
          reply: null,
          source: AiReplySource.error,
          error: 'Gemini returned an empty reply.',
        );
      }
      return AiChatResult(reply: text, source: AiReplySource.geminiDirect);
    } on TimeoutException {
      return const AiChatResult(
        reply: null,
        source: AiReplySource.error,
        error: 'Gemini request timed out.',
      );
    } catch (e, st) {
      if (_shouldTryNextModel(e.toString()) && _activeModelIndex < _candidateModels.length - 1) {
        _activeModelIndex++;
        _chatSession = null;
        _model = null;
        return _sendDirect(userMessage, attempt: attempt + 1);
      }
      if (kDebugMode) {
        debugPrint('Gemini error: $e');
        debugPrint('Stack: $st');
      }
      return AiChatResult(
        reply: null,
        source: AiReplySource.error,
        error: 'Gemini error: $e',
      );
    }
  }

  /// Reset conversation history.
  void clearHistory() {
    _chatSession = null;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool _shouldTryNextModel(String error) {
    final lower = error.toLowerCase();
    return lower.contains('not found') ||
        lower.contains('no longer available') ||
        lower.contains('is not supported for generatecontent') ||
        lower.contains('unsupported model');
  }
}
