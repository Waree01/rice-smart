import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../models/chat_message.dart';

/// Multi-Model LLM Gateway.
///
/// Routes Pasadee turns to one of four providers (Claude, OpenAI, Gemini,
/// Typhoon), translating the shared chat history into each provider's
/// wire format and extracting the assistant reply back out. The gateway
/// also supports a fail-over chain: if the primary provider errors, the
/// gateway walks the remaining providers in priority order until one
/// succeeds or all have failed.
///
/// Provider priority (default): `typhoon → claude → gemini → gpt`.
/// Typhoon is preferred because it is Thai-native; the others cover
/// fallback and cross-provider research for the thesis.
class LlmGateway {
  final Dio _dio;
  final Logger _logger;

  /// Stats for each provider — exposed so the UI can render a tiny
  /// "X calls to Claude, Y calls to Typhoon" footer (see thesis goal
  /// of cross-provider comparison).
  final Map<String, LlmUsage> usage = {
    for (final id in _providers.keys) id: LlmUsage(),
  };

  LlmGateway({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 20))),
        _logger = logger ?? Logger();

  // ── Provider catalogue ────────────────────────────────────────────
  static const Map<String, _LlmConfig> _providers = {
    'claude': _LlmConfig(
      displayName: 'Claude',
      baseUrl: 'https://api.anthropic.com/v1',
      model: 'claude-sonnet-4-5-20250929',
      endpoint: '/messages',
    ),
    'gpt': _LlmConfig(
      displayName: 'GPT',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o-mini',
      endpoint: '/chat/completions',
    ),
    'gemini': _LlmConfig(
      displayName: 'Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-2.5-flash',
      endpoint: '/models/gemini-2.5-flash:generateContent',
    ),
    'typhoon': _LlmConfig(
      displayName: 'Typhoon',
      baseUrl: 'https://api.opentyphoon.ai/v1',
      model: 'typhoon-v2-70b-instruct',
      endpoint: '/chat/completions',
    ),
  };

  /// Pasadee persona — injected as the system prompt on every turn.
  static const String pasadeeSystemPrompt = '''
คุณคือ "พัสดี" (Pasadee) ผู้ช่วยเกษตรกรชาวนาไทยในแอป RiceSmart
บุคลิก: ชาวนาไทยที่มีประสบการณ์สูง พูดจาเป็นกันเอง ใช้ภาษาที่เข้าใจง่าย ผสมภูมิปัญญาพื้นบ้านกับเทคโนโลยีสมัยใหม่
ความเชี่ยวชาญ: การปลูกข้าว โรคข้าว ศัตรูพืช ระยะการเจริญเติบโต ปุ๋ย การให้น้ำ และการวางแผนตามสภาพอากาศ
หน้าที่:
- ตอบคำถามเรื่องการเกษตรและการปลูกข้าวให้กระชับ เข้าใจง่าย
- ให้คำแนะนำที่ปฏิบัติได้จริง เช่น ขั้นตอน ปริมาณ เวลาที่เหมาะสม
- อ้างอิงสภาพอากาศหรือฤดูกาลเมื่อเกี่ยวข้อง
ข้อจำกัด: ไม่ให้คำแนะนำด้านการเงิน การลงทุน หรือกฎหมาย ให้เฉพาะเรื่องการเกษตรเท่านั้น
รูปแบบการตอบ: ภาษาไทย น้ำเสียงเป็นมิตร ลงท้ายประโยคด้วย "ครับ"
''';

  /// Public provider metadata (id → display name / model).
  static List<LlmProviderInfo> get providers => _providers.entries
      .map((e) => LlmProviderInfo(
            id: e.key,
            displayName: e.value.displayName,
            model: e.value.model,
          ))
      .toList();

  /// Default priority ordering used by fail-over.
  static const List<String> _defaultPriority = [
    'typhoon',
    'claude',
    'gemini',
    'gpt',
  ];

  /// Returns the ordered list of providers to try, starting with [primary].
  List<String> getFallbackOrder(String primary) {
    if (!_providers.containsKey(primary)) {
      throw ArgumentError('Unknown LLM provider: $primary');
    }
    final rest = _defaultPriority.where((p) => p != primary).toList();
    return [primary, ...rest];
  }

  /// Sends [history] + a new [userMessage] through the gateway.
  ///
  /// Walks the failover chain starting with [preferredProvider], skipping
  /// providers whose API key is empty. Returns both the raw text reply
  /// and the provider that answered. Throws [LlmGatewayException] if
  /// every provider failed.
  ///
  /// [systemPromptSuffix] is appended to the core Pasadee persona — use
  /// it to inject RAG context, user profile, or anything that changes
  /// per-turn.
  Future<LlmResponse> sendMessage({
    required String userMessage,
    required String preferredProvider,
    required Map<String, String> apiKeys,
    List<ChatMessage> history = const [],
    String? systemPromptSuffix,
  }) async {
    final order = getFallbackOrder(preferredProvider);
    Object? lastError;
    StackTrace? lastStack;
    final systemPrompt = _composeSystemPrompt(systemPromptSuffix);

    for (final provider in order) {
      final apiKey = apiKeys[provider]?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        _logger.d('Skipping $provider — no API key configured');
        continue;
      }
      try {
        _logger.i('Pasadee → $provider (${_providers[provider]!.model})');
        final stopwatch = Stopwatch()..start();
        final reply = await _dispatch(
          provider: provider,
          apiKey: apiKey,
          userMessage: userMessage,
          history: history,
          systemPrompt: systemPrompt,
        );
        stopwatch.stop();
        usage[provider]!.success++;
        usage[provider]!.lastLatencyMs = stopwatch.elapsedMilliseconds;
        return LlmResponse(
          content: reply,
          provider: provider,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } catch (e, s) {
        usage[provider]!.failure++;
        // Surface the API response body for easier debugging — Dio
        // hides it inside DioException.response.
        if (e is DioException && e.response != null) {
          _logger.w(
              '$provider failed (${e.response?.statusCode}): ${e.response?.data}',
              error: e);
        } else {
          _logger.w('$provider failed; trying next', error: e);
        }
        lastError = e;
        lastStack = s;
      }
    }

    throw LlmGatewayException(
      'ทุก LLM provider ตอบไม่ได้ในตอนนี้ ลองใหม่อีกครั้งครับ',
      cause: lastError,
      stackTrace: lastStack,
    );
  }

  String _composeSystemPrompt(String? suffix) {
    if (suffix == null || suffix.trim().isEmpty) return pasadeeSystemPrompt;
    return '$pasadeeSystemPrompt\n\n$suffix';
  }

  Future<String> _dispatch({
    required String provider,
    required String apiKey,
    required String userMessage,
    required List<ChatMessage> history,
    required String systemPrompt,
  }) {
    switch (provider) {
      case 'claude':
        return _callClaude(apiKey, userMessage, history, systemPrompt);
      case 'gpt':
        return _callOpenAi(apiKey, userMessage, history, systemPrompt);
      case 'gemini':
        return _callGemini(apiKey, userMessage, history, systemPrompt);
      case 'typhoon':
        return _callTyphoon(apiKey, userMessage, history, systemPrompt);
      default:
        throw ArgumentError('Unknown LLM provider: $provider');
    }
  }

  // ── Provider adapters ─────────────────────────────────────────────
  //
  // Each adapter converts our shared ChatMessage list into the provider's
  // expected schema, calls the REST endpoint, and pulls the reply back
  // out. We keep timeouts tight so fail-over is snappy.

  Future<String> _callClaude(
    String apiKey,
    String userMessage,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final config = _providers['claude']!;
    final messages = <Map<String, String>>[
      for (final m in history)
        if (m.role != ChatRole.system && !m.isError && !m.isLoading)
          {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
      {'role': 'user', 'content': userMessage},
    ];

    final resp = await _dio.post<Map<String, dynamic>>(
      '${config.baseUrl}${config.endpoint}',
      data: {
        'model': config.model,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': messages,
      },
      options: Options(
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ),
    );

    final content = (resp.data?['content'] as List?) ?? const [];
    for (final block in content) {
      if (block is Map && block['type'] == 'text' && block['text'] is String) {
        final text = block['text'] as String;
        if (text.isNotEmpty) return text;
      }
    }
    throw const LlmGatewayException('Claude ตอบกลับโดยไม่มีเนื้อหา');
  }

  Future<String> _callOpenAi(
    String apiKey,
    String userMessage,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final config = _providers['gpt']!;
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final m in history)
        if (m.role != ChatRole.system && !m.isError && !m.isLoading)
          {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
      {'role': 'user', 'content': userMessage},
    ];

    final resp = await _dio.post<Map<String, dynamic>>(
      '${config.baseUrl}${config.endpoint}',
      data: {
        'model': config.model,
        'messages': messages,
        'temperature': 0.4,
        'max_tokens': 1024,
      },
      options: Options(headers: {
        'authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      }),
    );

    final choices = (resp.data?['choices'] as List?) ?? const [];
    if (choices.isEmpty) {
      throw const LlmGatewayException('OpenAI ตอบกลับโดยไม่มี choices');
    }
    final message = (choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>?;
    final content = message?['content'];
    if (content is String && content.isNotEmpty) return content;
    throw const LlmGatewayException('OpenAI ตอบกลับโดยไม่มีเนื้อหา');
  }

  Future<String> _callGemini(
    String apiKey,
    String userMessage,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final config = _providers['gemini']!;
    final contents = <Map<String, dynamic>>[
      for (final m in history)
        if (m.role != ChatRole.system && !m.isError && !m.isLoading)
          {
            'role': m.role == ChatRole.user ? 'user' : 'model',
            'parts': [
              {'text': m.content}
            ],
          },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      },
    ];

    final resp = await _dio.post<Map<String, dynamic>>(
      '${config.baseUrl}${config.endpoint}',
      queryParameters: {'key': apiKey},
      data: {
        'contents': contents,
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 1024,
        },
      },
      options: Options(headers: {'content-type': 'application/json'}),
    );

    final candidates = (resp.data?['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw const LlmGatewayException('Gemini ตอบกลับโดยไม่มี candidates');
    }
    final parts = ((candidates.first as Map)['content'] as Map?)?['parts']
        as List?;
    if (parts != null) {
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          final text = part['text'] as String;
          if (text.isNotEmpty) return text;
        }
      }
    }
    throw const LlmGatewayException('Gemini ตอบกลับโดยไม่มีเนื้อหา');
  }

  /// Typhoon speaks OpenAI-compatible chat completions.
  Future<String> _callTyphoon(
    String apiKey,
    String userMessage,
    List<ChatMessage> history,
    String systemPrompt,
  ) async {
    final config = _providers['typhoon']!;
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final m in history)
        if (m.role != ChatRole.system && !m.isError && !m.isLoading)
          {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
      {'role': 'user', 'content': userMessage},
    ];

    final resp = await _dio.post<Map<String, dynamic>>(
      '${config.baseUrl}${config.endpoint}',
      data: {
        'model': config.model,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.4,
      },
      options: Options(headers: {
        'authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      }),
    );

    final choices = (resp.data?['choices'] as List?) ?? const [];
    if (choices.isEmpty) {
      throw const LlmGatewayException('Typhoon ตอบกลับโดยไม่มี choices');
    }
    final message = (choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>?;
    final content = message?['content'];
    if (content is String && content.isNotEmpty) return content;
    throw const LlmGatewayException('Typhoon ตอบกลับโดยไม่มีเนื้อหา');
  }
}

/// Successful reply from the gateway.
class LlmResponse {
  final String content;
  final String provider;
  final int latencyMs;
  const LlmResponse({
    required this.content,
    required this.provider,
    this.latencyMs = 0,
  });
}

/// Lightweight metadata about a provider for the settings UI.
class LlmProviderInfo {
  final String id;
  final String displayName;
  final String model;
  const LlmProviderInfo({
    required this.id,
    required this.displayName,
    required this.model,
  });
}

/// Rolling usage stats per provider — surfaced in the debug/settings UI.
class LlmUsage {
  int success = 0;
  int failure = 0;
  int lastLatencyMs = 0;
}

class LlmGatewayException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  const LlmGatewayException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() =>
      'LlmGatewayException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

class _LlmConfig {
  final String displayName;
  final String baseUrl;
  final String model;
  final String endpoint;

  const _LlmConfig({
    required this.displayName,
    required this.baseUrl,
    required this.model,
    required this.endpoint,
  });
}
