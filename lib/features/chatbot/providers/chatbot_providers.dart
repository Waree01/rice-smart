import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../config/env.dart';
import '../../../core/services/llm_gateway.dart';
import '../../../models/chat_message.dart';

/// Shared singleton — wraps Dio + provider adapters.
final llmGatewayProvider = Provider<LlmGateway>((ref) => LlmGateway());

/// UI-selected LLM provider. Persisted separately by the settings
/// controller; this provider is just the live state.
final preferredLlmProvider = StateProvider<String>((ref) => 'typhoon');

/// Chat history + loading state.
class ChatbotController extends StateNotifier<List<ChatMessage>> {
  ChatbotController(this._gateway, this._preferredProviderRef)
      : super([_greeting()]);

  final LlmGateway _gateway;
  final Ref _preferredProviderRef;
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
      final preferred = _preferredProviderRef.read(preferredLlmProvider);
      // History = everything in state *except* the greeting, the just-added
      // user turn (we pass it separately as userMessage), and the loading
      // placeholder that will hold the reply.
      final history = state
          .where((m) =>
              m.id != loadingMsg.id &&
              m.id != userMsg.id &&
              m.id != 'greeting' &&
              !m.isLoading &&
              !m.isError)
          .toList();
      final response = await _gateway.sendMessage(
        userMessage: trimmed,
        preferredProvider: preferred,
        apiKeys: Env.providerKeys,
        history: history,
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
  return ChatbotController(ref.watch(llmGatewayProvider), ref);
});
