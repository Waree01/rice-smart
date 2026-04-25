import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../config/env.dart';
import '../../../core/services/embedding_service.dart';
import '../../../core/services/llm_gateway.dart';
import '../../../core/services/rag_service.dart';
import '../../../models/chat_message.dart';
import '../../../models/farmer_profile.dart';
import '../../profile/providers/profile_providers.dart';

/// Shared singleton — wraps Dio + provider adapters.
final llmGatewayProvider = Provider<LlmGateway>((ref) => LlmGateway());

/// Embedding + RAG singletons.
final embeddingServiceProvider =
    Provider<EmbeddingService>((ref) => EmbeddingService());
final ragServiceProvider = Provider<RagService>(
  (ref) => RagService(
    embedder: ref.watch(embeddingServiceProvider),
  ),
);

/// Whether Pasadee should speak replies aloud (TTS).
final autoSpeakProvider = StateProvider<bool>((ref) => false);

/// UI-selected LLM provider. Persisted separately by the settings
/// controller; this provider is just the live state.
final preferredLlmProvider = StateProvider<String>((ref) => 'typhoon');

/// UI-selected embedding backend (for RAG thesis comparison).
final embeddingBackendProvider =
    StateProvider<EmbeddingBackend>((ref) => EmbeddingBackend.wangchanberta);

/// True once the RAG index is built (one-time per app launch).
final ragReadyProvider = StateProvider<bool>((ref) => false);

/// Chat history + loading state.
class ChatbotController extends StateNotifier<List<ChatMessage>> {
  ChatbotController(this._gateway, this._rag, this._ref) : super([_greeting()]);

  final LlmGateway _gateway;
  final RagService _rag;
  final Ref _ref;
  final _logger = Logger();
  final _uuid = const Uuid();

  static ChatMessage _greeting() => ChatMessage(
        id: 'greeting',
        role: ChatRole.assistant,
        content:
            'สวัสดีครับ! ผมพัสดี ชาวนาผู้ช่วยของคุณ 🌾\nถามเรื่องการปลูกข้าว โรคข้าว ศัตรูพืช หรือวางแผนตามสภาพอากาศได้เลยครับ',
        timestamp: DateTime.now(),
        provider: 'pasadee',
      );

  /// Append a user turn and request a Pasadee reply.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    final loadingMsg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.assistant,
      content: 'กำลังคิด...',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, userMsg, loadingMsg];

    try {
      final preferred = _ref.read(preferredLlmProvider);
      final profile = _ref.read(profileControllerProvider);
      // History = state minus greeting, just-added user turn, and the
      // loading placeholder we're about to fill.
      final history = state
          .where(
            (m) =>
                m.id != loadingMsg.id &&
                m.id != userMsg.id &&
                m.id != 'greeting' &&
                !m.isLoading &&
                !m.isError,
          )
          .toList();

      final suffix = await _buildSystemPromptSuffix(trimmed, profile);
      final response = await _gateway.sendMessage(
        userMessage: trimmed,
        preferredProvider: preferred,
        apiKeys: Env.providerKeys,
        history: history,
        systemPromptSuffix: suffix,
      );
      state = [
        for (final m in state)
          if (m.id == loadingMsg.id)
            m.copyWith(
              content: response.content,
              isLoading: false,
              provider: response.provider,
            )
          else
            m,
      ];
    } catch (e, s) {
      _logger.e('Pasadee reply failed', error: e, stackTrace: s);
      state = [
        for (final m in state)
          if (m.id == loadingMsg.id)
            m.copyWith(
              content: _friendlyError(e),
              isLoading: false,
              isError: true,
            )
          else
            m,
      ];
    }
  }

  /// Compose the per-turn system prompt suffix from profile + RAG hits.
  Future<String?> _buildSystemPromptSuffix(
    String query,
    FarmerProfile? profile,
  ) async {
    final parts = <String>[];
    if (profile != null) {
      final buf = StringBuffer('บริบทของชาวนา:');
      buf.write(' ชื่อ "${profile.name}"');
      if (profile.provinceTh != null && profile.provinceTh!.isNotEmpty) {
        buf.write(' จังหวัด ${profile.provinceTh}');
      }
      if (profile.farmSizeRai != null) {
        buf.write(' แปลงนา ${profile.farmSizeRai!.toStringAsFixed(1)} ไร่');
      }
      parts.add(buf.toString());
    }

    if (_rag.isIndexed) {
      final apiKey = _embeddingApiKey(_rag.activeBackend);
      final suffix = await _rag.buildPromptSuffix(query: query, apiKey: apiKey);
      if (suffix != null) parts.add(suffix);
    }

    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  String _embeddingApiKey(EmbeddingBackend backend) {
    switch (backend) {
      case EmbeddingBackend.wangchanberta:
        return Env.huggingFaceApiKey;
      case EmbeddingBackend.openai:
        return Env.openaiApiKey;
    }
  }

  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('ทุก LLM') || raw.contains('LlmGatewayException')) {
      return 'ขออภัยครับ ตอนนี้พัสดีติดต่อเครื่องช่วยคิดไม่ได้ กรุณาตั้งค่า API key ในไฟล์ .env '
          'หรือลองใหม่อีกครั้งหลังจากเช็คสัญญาณอินเทอร์เน็ต';
    }
    return 'ขออภัยครับ เกิดข้อผิดพลาด: $raw';
  }

  /// Wipe history back to the greeting.
  void clear() => state = [_greeting()];
}

final chatbotControllerProvider =
    StateNotifierProvider<ChatbotController, List<ChatMessage>>((ref) {
  return ChatbotController(
    ref.watch(llmGatewayProvider),
    ref.watch(ragServiceProvider),
    ref,
  );
});
