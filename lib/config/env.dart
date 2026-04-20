import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment variables - API keys loaded securely via envied
/// Run: dart run build_runner build
///
/// Create a .env file in the project root with:
///   CLAUDE_API_KEY=your_key_here
///   OPENAI_API_KEY=your_key_here
///   GEMINI_API_KEY=your_key_here
///   TYPHOON_API_KEY=your_key_here
///   TMD_API_KEY=your_key_here
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'CLAUDE_API_KEY')
  static const String claudeApiKey = _Env.claudeApiKey;

  @EnviedField(varName: 'OPENAI_API_KEY')
  static const String openaiApiKey = _Env.openaiApiKey;

  @EnviedField(varName: 'GEMINI_API_KEY')
  static const String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(varName: 'TYPHOON_API_KEY')
  static const String typhoonApiKey = _Env.typhoonApiKey;

  @EnviedField(varName: 'TMD_API_KEY')
  static const String tmdApiKey = _Env.tmdApiKey;
}
