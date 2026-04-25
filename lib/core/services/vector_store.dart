/// A single retrievable chunk: a short Thai passage plus its embedding.
class Document {
  final String id;
  final String text;
  final String category; // 'disease', 'pest', 'stage', 'practice'
  final Map<String, dynamic> metadata;
  final List<double> embedding;

  const Document({
    required this.id,
    required this.text,
    required this.category,
    required this.metadata,
    required this.embedding,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
        'metadata': metadata,
        'embedding': embedding,
      };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        text: json['text'] as String,
        category: json['category'] as String,
        metadata: (json['metadata'] as Map).cast<String, dynamic>(),
        embedding: (json['embedding'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}

/// Search result with its similarity score.
class ScoredDocument {
  final Document document;
  final double score;
  const ScoredDocument({required this.document, required this.score});
}

/// In-memory vector store. Small enough (< 1000 docs) that brute-force
/// cosine similarity is plenty fast — we don't need an HNSW index here.
///
/// Embeddings are pre-normalized by [EmbeddingService], so cosine
/// similarity reduces to a dot product.
class VectorStore {
  final List<Document> _docs = [];

  int get length => _docs.length;
  bool get isEmpty => _docs.isEmpty;
  List<Document> get documents => List.unmodifiable(_docs);

  void add(Document doc) => _docs.add(doc);

  void addAll(Iterable<Document> docs) => _docs.addAll(docs);

  void clear() => _docs.clear();

  /// Top-[k] documents by cosine similarity with [query]. Returns an
  /// empty list if the store is empty or vector dims mismatch.
  List<ScoredDocument> search(List<double> query, {int k = 4}) {
    if (_docs.isEmpty || query.isEmpty) return const [];
    final scored = <ScoredDocument>[];
    for (final doc in _docs) {
      if (doc.embedding.length != query.length) continue;
      final score = _dot(query, doc.embedding);
      scored.add(ScoredDocument(document: doc, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).toList();
  }

  static double _dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  /// Serialize the whole store. Useful to cache embeddings to disk so
  /// we only pay the HuggingFace cost once per corpus version.
  List<Map<String, dynamic>> toJson() => _docs.map((d) => d.toJson()).toList();

  void loadJson(List<dynamic> raw) {
    _docs
      ..clear()
      ..addAll(
        raw.cast<Map<String, dynamic>>().map((m) => Document.fromJson(m)),
      );
  }
}
