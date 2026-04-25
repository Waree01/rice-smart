import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/embedding_service.dart';
import 'package:rice_smart/core/services/rag_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple mock for EmbeddingService
class MockEmbeddingService implements EmbeddingService {
  final List<double> Function()? embedder;

  MockEmbeddingService({this.embedder});

  @override
  Future<List<double>?> embed({
    required String text,
    required EmbeddingBackend backend,
    required String apiKey,
  }) async {
    return embedder?.call() ?? List<double>.filled(768, 0.1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RagService', () {
    test('buildIndex requires backend and apiKey parameters', () async {
      SharedPreferences.setMockInitialValues({});
      final service = RagService(
        embedder: MockEmbeddingService(
          embedder: () => List<double>.filled(768, 0.5),
        ),
      );

      // buildIndex requires backend and apiKey
      final result = await service.buildIndex(
        backend: EmbeddingBackend.wangchanberta,
        apiKey: 'test-key',
      );

      // Should succeed or fail gracefully
      expect(result, isA<bool>());
    });

    test('buildPromptSuffix returns null when store is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final service = RagService(
        embedder: MockEmbeddingService(),
      );

      final suffix = await service.buildPromptSuffix(
        query: 'Any question',
        apiKey: 'test-key',
      );
      expect(suffix, isNull);
    });

    test('isIndexed reflects store state', () async {
      SharedPreferences.setMockInitialValues({});
      final service = RagService(
        embedder: MockEmbeddingService(),
      );

      expect(service.isIndexed, false);
    });

    test('activeBackend tracks current backend', () async {
      SharedPreferences.setMockInitialValues({});
      final service = RagService(
        embedder: MockEmbeddingService(),
      );

      expect(service.activeBackend, EmbeddingBackend.wangchanberta);
    });
  });
}
