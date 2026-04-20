import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Multi-Model LLM Gateway
/// Routes requests to Claude, GPT, Gemini, or Typhoon
/// with automatic failover and cost tracking
///
/// Architecture:
///   User Input → Pasadee Persona Prompt → LLM Gateway → Response
///   The gateway wraps user questions in Pasadee's farmer persona
///   before sending to the selected LLM provider.
class LlmGateway {
  final Dio _dio;
  final Logger _logger = Logger();

  // Provider configurations
  static const Map<String, _LlmConfig> _providers = {
    'claude': _LlmConfig(
      baseUrl: 'https://api.anthropic.com/v1',
      model: 'claude-sonnet-4-20250514',
      endpoint: '/messages',
    ),
    'gpt': _LlmConfig(
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o',
      endpoint: '/chat/completions',
    ),
    'gemini': _LlmConfig(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-1.5-pro',
      endpoint: '/models/gemini-1.5-pro:generateContent',
    ),
    'typhoon': _LlmConfig(
      baseUrl: 'https://api.opentyphoon.ai/v1',
      model: 'typhoon-v1.5-instruct',
      endpoint: '/chat/completions',
    ),
  };

  // Pasadee system prompt - virtual farmer persona
  static const String _pasadeeSystemPrompt = '''
คุณคือ "พัสดี" (Pasadee) ผู้ช่วยชาวนาอัจฉริยะในแอป RiceSmart
บุคลิก: ชาวนาไทยที่มีประสบการณ์ พูดจาเป็นกันเอง ใช้ภาษาที่เข้าใจง่าย
ความเชี่ยวชาญ: การปลูกข้าว โรคข้าว ศัตรูพืช สภาพอากาศที่เหมาะสม
หน้าที่: ให้คำแนะนำเรื่องการปลูกข้าวตามภูมิปัญญาไทยผสมผสานกับเทคโนโลยี AI
ข้อจำกัด: ไม่ให้คำแนะนำด้านการเงินหรือการลงทุน ให้เฉพาะเรื่องการเกษตร
ตอบเป็นภาษาไทย ใช้คำลงท้ายว่า "ครับ"
''';

  LlmGateway({Dio? dio}) : _dio = dio ?? Dio();

  /// Send message to selected LLM provider with Pasadee persona
  /// Falls back to next provider on failure
  Future<String> sendMessage({
    required String userMessage,
    required String provider,
    required String apiKey,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final config = _providers[provider];
    if (config == null) {
      throw ArgumentError('Unknown LLM provider: $provider');
    }

    try {
      _logger.i('Sending to $provider: ${config.model}');

      // TODO: Implement provider-specific API calls
      // Each provider has different request/response formats
      // This is a placeholder for the gateway pattern

      return 'พัสดีกำลังคิด... (Provider: $provider)';
    } catch (e) {
      _logger.e('Error with $provider', error: e);
      rethrow;
    }
  }

  /// Get ordered list of fallback providers
  List<String> getFallbackOrder(String primary) {
    final order = ['typhoon', 'claude', 'gemini', 'gpt'];
    order.remove(primary);
    return [primary, ...order];
  }
}

class _LlmConfig {
  final String baseUrl;
  final String model;
  final String endpoint;

  const _LlmConfig({
    required this.baseUrl,
    required this.model,
    required this.endpoint,
  });
}
