import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Cloud vision fallback for low-confidence on-device predictions.
///
/// When the on-device TFLite model isn't confident enough (< 75%), we
/// offer the farmer an optional "second opinion" by sending the image
/// to a vision-capable LLM. This is the cloud escalation pattern used
/// in the thesis's hybrid on-device + cloud architecture.
///
/// Supported providers:
///   - Claude 3.5 Sonnet (vision) via Anthropic Messages API
///   - Gemini 1.5 Pro (vision) via Google AI Studio
///
/// Both providers take base64-encoded JPEG/PNG; we compress nothing
/// extra here because image_picker already resized to 1024px.
class MultimodalVisionService {
  MultimodalVisionService({Dio? dio, Logger? logger})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 45),
            )),
        _logger = logger ?? Logger();

  final Dio _dio;
  final Logger _logger;

  /// Describes the user's question to Pasadee's cloud counterpart.
  static const String _diseasePrompt = '''
คุณคือผู้เชี่ยวชาญด้านโรคข้าวของไทย จงวินิจฉัยภาพนี้อย่างละเอียด
1. ระบุชื่อโรค (ไทยและอังกฤษ) ถ้าเห็นไม่ชัดให้บอกว่าไม่แน่ใจ
2. ระดับความรุนแรง (น้อย/กลาง/รุนแรง/วิกฤต)
3. สาเหตุและเงื่อนไขที่ทำให้เกิดโรค
4. แผนการจัดการ 3-5 ข้อที่ปฏิบัติได้จริง
ตอบเป็นภาษาไทยแบบชาวนาเข้าใจง่าย ลงท้าย "ครับ"
''';

  static const String _pestPrompt = '''
คุณคือผู้เชี่ยวชาญด้านศัตรูพืชข้าวของไทย จงวินิจฉัยภาพนี้
1. ระบุชนิดแมลง (ไทยและอังกฤษ)
2. ระดับความเสียหายในภาพ
3. แนวทางจัดการ IPM 3-5 ข้อ
ตอบเป็นภาษาไทยสำหรับชาวนา ลงท้าย "ครับ"
''';

  Future<CloudVisionResult> analyzeDisease({
    required String imagePath,
    required String provider,
    required String apiKey,
  }) {
    return _analyze(
      imagePath: imagePath,
      provider: provider,
      apiKey: apiKey,
      prompt: _diseasePrompt,
    );
  }

  Future<CloudVisionResult> analyzePest({
    required String imagePath,
    required String provider,
    required String apiKey,
  }) {
    return _analyze(
      imagePath: imagePath,
      provider: provider,
      apiKey: apiKey,
      prompt: _pestPrompt,
    );
  }

  Future<CloudVisionResult> _analyze({
    required String imagePath,
    required String provider,
    required String apiKey,
    required String prompt,
  }) async {
    if (apiKey.isEmpty) {
      throw const MultimodalException('ยังไม่ได้ตั้งค่า API key ของคลาวด์');
    }
    final bytes = await File(imagePath).readAsBytes();
    final b64 = base64Encode(bytes);
    final mediaType = _guessMediaType(imagePath);

    _logger.i('Cloud vision → $provider (${bytes.length} bytes)');
    switch (provider) {
      case 'claude':
        return _callClaude(apiKey, prompt, b64, mediaType);
      case 'gemini':
        return _callGemini(apiKey, prompt, b64, mediaType);
      default:
        throw MultimodalException('Provider $provider ยังไม่รองรับ vision');
    }
  }

  Future<CloudVisionResult> _callClaude(
    String apiKey,
    String prompt,
    String b64,
    String mediaType,
  ) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      'https://api.anthropic.com/v1/messages',
      data: {
        'model': 'claude-sonnet-4-5-20250929',
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': b64,
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
      },
      options: Options(headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
    );
    final content = (resp.data?['content'] as List?) ?? const [];
    for (final block in content) {
      if (block is Map &&
          block['type'] == 'text' &&
          block['text'] is String) {
        final text = block['text'] as String;
        if (text.isNotEmpty) {
          return CloudVisionResult(text: text, provider: 'claude');
        }
      }
    }
    throw const MultimodalException('Claude ตอบกลับโดยไม่มีเนื้อหา');
  }

  Future<CloudVisionResult> _callGemini(
    String apiKey,
    String prompt,
    String b64,
    String mediaType,
  ) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.5-flash:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mediaType,
                  'data': b64,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1024,
        },
      },
      options: Options(headers: {'content-type': 'application/json'}),
    );
    final candidates = (resp.data?['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw const MultimodalException('Gemini ตอบกลับโดยไม่มี candidates');
    }
    final parts = ((candidates.first as Map)['content'] as Map?)?['parts']
        as List?;
    if (parts != null) {
      for (final p in parts) {
        if (p is Map && p['text'] is String) {
          final text = p['text'] as String;
          if (text.isNotEmpty) {
            return CloudVisionResult(text: text, provider: 'gemini');
          }
        }
      }
    }
    throw const MultimodalException('Gemini ตอบกลับโดยไม่มีเนื้อหา');
  }

  String _guessMediaType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class CloudVisionResult {
  final String text;
  final String provider;
  const CloudVisionResult({required this.text, required this.provider});
}

class MultimodalException implements Exception {
  final String message;
  const MultimodalException(this.message);
  @override
  String toString() => 'MultimodalException: $message';
}
