import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment — loads secrets from an asset-bundled `.env` file.
///
/// Setup:
/// 1. Copy `.env.example` to `.env` at the project root.
/// 2. Populate the keys you need (missing keys degrade gracefully).
/// 3. Call `await Env.load()` from `main()` before `runApp`.
///
/// Security notes:
/// * `.env` is bundled as an asset; this is NOT a strong secret store.
///   For a production release, provision real keys via CI secrets and
///   inject them at build time, or route LLM calls through a backend
///   proxy so the client never holds provider keys.
/// * Treat API keys as semi-public — rotate on any suspected leak.
abstract class Env {
  static bool _loaded = false;

  /// Loads environment variables. Tries `.env` first (developer local
  /// override, gitignored), then `.env.example` (bundled default with
  /// empty values). Safe to call multiple times.
  static Future<void> load() async {
    if (_loaded) return;
    for (final candidate in const ['.env', '.env.example']) {
      try {
        await dotenv.load(fileName: candidate);
        break;
      } catch (_) {
        // Try next candidate.
      }
    }
    _loaded = true;
  }

  static String _get(String key) => dotenv.maybeGet(key) ?? '';

  static String get claudeApiKey => _get('CLAUDE_API_KEY');
  static String get openaiApiKey => _get('OPENAI_API_KEY');
  static String get geminiApiKey => _get('GEMINI_API_KEY');
  static String get typhoonApiKey => _get('TYPHOON_API_KEY');
  static String get tmdApiKey => _get('TMD_API_KEY');
  static String get huggingFaceApiKey => _get('HUGGINGFACE_API_KEY');

  /// True once `load()` has completed (or silently failed).
  static bool get isLoaded => _loaded;

  /// Map of provider id → api key. Used by `LlmGateway.sendMessage`.
  static Map<String, String> get providerKeys => {
        'claude': claudeApiKey,
        'gpt': openaiApiKey,
        'gemini': geminiApiKey,
        'typhoon': typhoonApiKey,
      };
}
