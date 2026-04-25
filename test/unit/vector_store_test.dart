import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/vector_store.dart';

void main() {
  group('VectorStore', () {
    Document doc(String id, List<double> e) => Document(
          id: id,
          text: 'text for $id',
          category: 'test',
          metadata: const {},
          embedding: e,
        );

    test('retrieves nearest document by cosine similarity', () {
      final store = VectorStore()
        ..add(doc('a', [1.0, 0.0]))
        ..add(doc('b', [0.0, 1.0]))
        ..add(doc('c', [0.7071, 0.7071]));

      final hits = store.search([1.0, 0.0], k: 2);
      expect(hits, hasLength(2));
      expect(hits.first.document.id, 'a');
      expect(hits.first.score, closeTo(1.0, 1e-6));
      // 'c' is 45° off → cos = 0.7071
      expect(hits[1].document.id, 'c');
    });

    test('skips documents with mismatched dimensions', () {
      final store = VectorStore()
        ..add(doc('short', [1.0]))
        ..add(doc('ok', [1.0, 0.0]));

      final hits = store.search([1.0, 0.0], k: 2);
      expect(hits, hasLength(1));
      expect(hits.first.document.id, 'ok');
    });

    test('handles empty store gracefully', () {
      expect(VectorStore().search([1, 0]), isEmpty);
    });

    test('JSON roundtrip preserves documents', () {
      final original = VectorStore()
        ..add(doc('a', [0.5, 0.5]))
        ..add(doc('b', [0.1, 0.9]));
      final encoded = original.toJson();
      final roundTrip = VectorStore()..loadJson(encoded);
      expect(roundTrip.length, 2);
      expect(roundTrip.documents.first.embedding, [0.5, 0.5]);
    });
  });
}
