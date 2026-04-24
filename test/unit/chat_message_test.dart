import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final now = DateTime(2026, 4, 24, 12, 0);

    test('copyWith preserves identity but swaps overrideable fields', () {
      final msg = ChatMessage(
        id: 'abc',
        role: ChatRole.assistant,
        content: 'hello',
        timestamp: now,
      );

      final updated = msg.copyWith(content: 'hi', isLoading: false);
      expect(updated.id, 'abc');
      expect(updated.role, ChatRole.assistant);
      expect(updated.content, 'hi');
      expect(updated.timestamp, now);
    });

    test('JSON roundtrip retains role, content, and provider', () {
      final original = ChatMessage(
        id: 'id-1',
        role: ChatRole.user,
        content: 'สวัสดีพัสดี',
        timestamp: now,
        provider: 'typhoon',
      );

      final clone = ChatMessage.fromJson(original.toJson());
      expect(clone.id, original.id);
      expect(clone.role, ChatRole.user);
      expect(clone.content, 'สวัสดีพัสดี');
      expect(clone.provider, 'typhoon');
    });

    test('fromJson tolerates an unknown role by defaulting to assistant', () {
      final clone = ChatMessage.fromJson({
        'id': 'x',
        'role': 'bot',
        'content': 'hi',
        'timestamp': now.toIso8601String(),
      });
      expect(clone.role, ChatRole.assistant);
    });
  });
}
