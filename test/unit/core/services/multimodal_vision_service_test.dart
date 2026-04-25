import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/multimodal_vision_service.dart';

void main() {
  // Initialize Flutter bindings for unit tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudVisionResult', () {
    test('CloudVisionResult stores text and provider', () {
      const result = CloudVisionResult(
        text: 'This is a disease',
        provider: 'claude',
      );

      expect(result.text, 'This is a disease');
      expect(result.provider, 'claude');
    });

    test('CloudVisionResult with different providers', () {
      const result = CloudVisionResult(
        text: 'Gemini response',
        provider: 'gemini',
      );

      expect(result.provider, 'gemini');
    });
  });

  group('MultimodalException', () {
    test('MultimodalException stores message', () {
      const exception = MultimodalException('ยังไม่ได้ตั้งค่า API key');
      expect(exception.message, 'ยังไม่ได้ตั้งค่า API key');
    });

    test('MultimodalException has correct string representation', () {
      const exception = MultimodalException('Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('MultimodalException is an Exception', () {
      const exception = MultimodalException('Test');
      expect(exception, isA<Exception>());
    });
  });

  group('MultimodalVisionService', () {
    late MultimodalVisionService service;

    setUp(() {
      service = MultimodalVisionService();
    });

    test('analyzeDisease throws MultimodalException on empty apiKey', () {
      expect(
        () => service.analyzeDisease(
          imagePath: 'assets/images/placeholder.png',
          provider: 'claude',
          apiKey: '',
        ),
        throwsA(isA<MultimodalException>()),
      );
    });

    test('analyzePest throws MultimodalException on empty apiKey', () {
      expect(
        () => service.analyzePest(
          imagePath: 'assets/images/placeholder.png',
          provider: 'claude',
          apiKey: '',
        ),
        throwsA(isA<MultimodalException>()),
      );
    });

    test('analyzeDisease throws on unsupported provider', () {
      expect(
        () => service.analyzeDisease(
          imagePath: 'assets/images/placeholder.png',
          provider: 'unsupported',
          apiKey: 'key',
        ),
        throwsA(isA<MultimodalException>()),
      );
    });

    test('analyzePest throws on unsupported provider', () {
      expect(
        () => service.analyzePest(
          imagePath: 'assets/images/placeholder.png',
          provider: 'unsupported',
          apiKey: 'key',
        ),
        throwsA(isA<MultimodalException>()),
      );
    });
  });
}
