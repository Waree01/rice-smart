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

    test('getFallbackOrder always starts with requested primary', () {
      expect(gateway.getFallbackOrder('gpt')[0], 'gpt');
      expect(gateway.getFallbackOrder('claude')[0], 'claude');
      expect(gateway.getFallbackOrder('gemini')[0], 'gemini');
      expect(gateway.getFallbackOrder('typhoon')[0], 'typhoon');
    });

    test('getFallbackOrder returns 4 providers', () {
      expect(gateway.getFallbackOrder('claude').length, 4);
      expect(gateway.getFallbackOrder('gpt').length, 4);
    });

    test('getFallbackOrder does not repeat providers', () {
      final order = gateway.getFallbackOrder('claude');
      expect(order.toSet().length, order.length);
    });

    test('provider catalogue includes Claude with correct model', () {
      final claude = LlmGateway.providers.firstWhere((p) => p.id == 'claude');
      expect(claude.displayName, 'Claude');
      expect(claude.model, contains('claude'));
    });

    test('provider catalogue includes Typhoon with correct model', () {
      final typhoon = LlmGateway.providers.firstWhere((p) => p.id == 'typhoon');
      expect(typhoon.displayName, 'Typhoon');
      expect(typhoon.model, contains('typhoon'));
    });

    test('Pasadee prompt includes farming expertise keywords', () {
      const p = LlmGateway.pasadeeSystemPrompt;
      expect(p, contains('ข้าว'));
      expect(p, contains('โรค'));
      expect(p, contains('ศัตรูพืช'));
    });

    test('Pasadee prompt explicitly excludes financial advice', () {
      const p = LlmGateway.pasadeeSystemPrompt;
      expect(p, contains('ไม่ให้'));
      expect(p, contains('การเงิน'));
    });

    test('usage tracker is initialized for all providers', () {
      expect(gateway.usage.keys.length, 4);
      expect(gateway.usage.containsKey('claude'), true);
      expect(gateway.usage.containsKey('gpt'), true);
      expect(gateway.usage.containsKey('gemini'), true);
      expect(gateway.usage.containsKey('typhoon'), true);
    });

    test('usage entries start with zero calls', () {
      for (final usage in gateway.usage.values) {
        expect(usage.success, 0);
        expect(usage.failure, 0);
      }
    });
  });

  group('LlmResponse', () {
    test('LlmResponse stores content, provider, and latency', () {
      const response = LlmResponse(
        content: 'Test response',
        provider: 'claude',
        latencyMs: 250,
      );

      expect(response.content, 'Test response');
      expect(response.provider, 'claude');
      expect(response.latencyMs, 250);
    });
  });

  group('LlmUsage', () {
    test('LlmUsage initializes with zero calls', () {
      final usage = LlmUsage();
      expect(usage.success, 0);
      expect(usage.failure, 0);
      expect(usage.lastLatencyMs, 0);
    });

    test('LlmUsage tracks total calls', () {
      final usage = LlmUsage()
        ..success = 5
        ..failure = 2;

      expect(usage.success, 5);
      expect(usage.failure, 2);
    });
  });

  group('LlmProviderInfo', () {
    test('LlmProviderInfo stores id, displayName, and model', () {
      const info = LlmProviderInfo(
        id: 'test-provider',
        displayName: 'Test Provider',
        model: 'test-model-1.0',
      );

      expect(info.id, 'test-provider');
      expect(info.displayName, 'Test Provider');
      expect(info.model, 'test-model-1.0');
    });
  });

  group('LlmGatewayException', () {
    test('LlmGatewayException has correct string representation', () {
      const exception = LlmGatewayException('All providers failed');
      expect(exception.toString(), contains('All providers failed'));
    });
  });
}
