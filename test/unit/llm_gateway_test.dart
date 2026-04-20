import 'package:flutter_test/flutter_test.dart';

// TODO: Import and test LlmGateway once build_runner generates files

void main() {
  group('LlmGateway', () {
    test('should return ordered fallback providers', () {
      // TODO: Test fallback ordering
      // Given primary = 'claude'
      // Expected: ['claude', 'typhoon', 'gemini', 'gpt']
    });

    test('should throw on unknown provider', () {
      // TODO: Test error handling for invalid provider names
    });

    test('should include Pasadee system prompt', () {
      // TODO: Verify Pasadee persona is injected into all requests
    });
  });

  group('WeatherService', () {
    test('should calculate disease risk score correctly', () {
      // High risk conditions: 26°C, 90% humidity, 15mm rain
      // Expected: risk > 0.8
    });

    test('should calculate GDD correctly', () {
      // maxTemp=35, minTemp=25, base=10
      // GDD = ((35+25)/2) - 10 = 20
    });

    test('should fallback to NASA POWER when TMD fails', () {
      // TODO: Mock TMD failure and verify NASA fallback
    });
  });
}
