import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/llm_gateway.dart';

void main() {
  group('LlmGateway', () {
    final gateway = LlmGateway();

    test('returns the requested primary first, then the rest in priority order',
        () {
      expect(
        gateway.getFallbackOrder('claude'),
        ['claude', 'typhoon', 'gemini', 'gpt'],
      );
      expect(
        gateway.getFallbackOrder('typhoon'),
        ['typhoon', 'claude', 'gemini', 'gpt'],
      );
      expect(
        gateway.getFallbackOrder('gemini'),
        ['gemini', 'typhoon', 'claude', 'gpt'],
      );
    });

    test('throws ArgumentError on an unknown provider id', () {
      expect(
        () => gateway.getFallbackOrder('grok'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Pasadee system prompt mentions the persona in Thai', () {
      const p = LlmGateway.pasadeeSystemPrompt;
      expect(p, contains('พัสดี'));
      expect(p, contains('ชาวนา'));
      expect(p, contains('ครับ'));
    });

    test('provider catalogue exposes all four providers', () {
      final ids = LlmGateway.providers.map((p) => p.id).toSet();
      expect(ids, {'claude', 'gpt', 'gemini', 'typhoon'});
    });

    test('sendMessage rejects a preferred provider that is not configured',
        () async {
      expect(
        () => gateway.sendMessage(
          userMessage: 'สวัสดี',
          preferredProvider: 'grok',
          apiKeys: const {},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('sendMessage throws LlmGatewayException when no keys are configured',
        () async {
      await expectLater(
        () => gateway.sendMessage(
          userMessage: 'สวัสดี',
          preferredProvider: 'typhoon',
          apiKeys: const {
            'typhoon': '',
            'claude': '',
            'gpt': '',
            'gemini': '',
          },
        ),
        throwsA(isA<LlmGatewayException>()),
      );
    });
  });
}
