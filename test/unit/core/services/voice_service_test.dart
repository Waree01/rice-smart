import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/voice_service.dart';

void main() {
  // Initialize Flutter bindings for unit tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceService', () {
    late VoiceService service;

    setUp(() {
      service = VoiceService();
    });

    test('isListening returns false by default', () {
      expect(service.isListening, false);
    });

    test('initStt returns a bool', () async {
      final result = await service.initStt();
      expect(result, isA<bool>());
    });

    test('initTts completes without throwing', () async {
      // TTS initialization should complete gracefully
      await service.initTts();
      // No assertion needed - just ensure it doesn't throw
      expect(true, true);
    });

    test('speak completes without throwing', () async {
      // Just ensure speak doesn't throw
      await service.speak('สวัสดี');
      expect(true, true);
    });

    test('stopSpeaking completes without throwing', () async {
      await service.stopSpeaking();
      expect(true, true);
    });

    test('stopListening completes without throwing', () async {
      await service.stopListening();
      expect(true, true);
    });

    test('startListening returns a bool', () async {
      final result = await service.startListening(
        onResult: (text, finalResult) {},
      );

      expect(result, isA<bool>());
      // Clean up
      await service.stopListening();
    });

    test('speak handles Thai text', () async {
      // Should not throw
      await service.speak('ข้าวหลวง');
      expect(true, true);
    });

    test('initStt can be called multiple times safely', () async {
      final result1 = await service.initStt();
      final result2 = await service.initStt();

      expect(result1, isA<bool>());
      expect(result2, isA<bool>());
    });

    test('initTts can be called multiple times safely', () async {
      await service.initTts();
      await service.initTts();
      expect(true, true);
    });
  });
}
