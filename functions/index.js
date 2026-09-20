const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { GoogleGenerativeAI } = require("@google/generative-ai");
require("dotenv").config();

// Set in functions/.env (local) or Firebase Console > Functions > env vars (production)
const getApiKey = () => process.env.GEMINI_API_KEY || "";
const candidateModels = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-1.5-flash-latest"];

const chatSessions = new Map(); // In-memory session store (use Redis/DB for production)

exports.chatWithGemini = onCall(
  {
    cors: true,
  },
  async (request) => {
    if (!request.auth && !request.rawRequest.headers.origin) {
      // Allow unauthenticated for demo; restrict in production
    }

    const { message, sessionId } = request.data || {};
    if (!message || typeof message !== "string") {
      throw new HttpsError("invalid-argument", "message is required");
    }

    const apiKey = getApiKey();
    if (!apiKey) {
      throw new HttpsError(
        "failed-precondition",
        "Gemini API key not configured. Add GEMINI_API_KEY to functions/.env or Firebase config."
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const systemInstruction =
      "You are a friendly AI travel assistant for Khedne Ma3ak, an app for discovering places in Lebanon. " +
      "Answer naturally about restaurants, hotels, pools, beaches. Mention Lebanese cities when relevant. " +
      "Keep responses concise (2-4 sentences) and personable.";

    let lastError = null;
    for (const modelName of candidateModels) {
      try {
        const model = genAI.getGenerativeModel({
          model: modelName,
          systemInstruction,
        });

        let chat = chatSessions.get(sessionId);
        if (!chat) {
          chat = model.startChat();
          if (sessionId) chatSessions.set(sessionId, chat);
        }

        const result = await chat.sendMessage(message);
        const response = result.response;
        const text = response.text();
        return { reply: text, model: modelName };
      } catch (err) {
        lastError = err;
        const lower = String(err).toLowerCase();
        const canRetryModel =
          lower.includes("not found") ||
          lower.includes("no longer available") ||
          lower.includes("not supported");
        if (!canRetryModel) {
          break;
        }
      }
    }

    throw new HttpsError(
      "internal",
      `Gemini request failed: ${lastError ?? "Unknown error"}`
    );
  }
);
