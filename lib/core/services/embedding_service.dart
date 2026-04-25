import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Embedding providers currently wired up.
///
/// The project ships with two options so the thesis can run a
/// side-by-side retrieval quality study:
///   * [wangchanberta]  — Thai-native, served via HuggingFace Inference API.
///   * [openai]         — multilingual, requires an OpenAI key.
enum EmbeddingBackend {
  wangchanberta,
  openai,
}

/// Thin wrapper over an embedding API that returns a unit-normalized
/// vector for a string. Used by [VectorStore] to power RAG retrieval.
///
/// Both backends return 768-dim (WangchanBERTa) or 1536-dim
/// (OpenAI text-embedding-3-small) vectors; `VectorStore` treats them
/// as opaque `List<double>` so you can mix and match per corpus.
class EmbeddingService {
  EmbeddingService({Dio? dio, Logger? logger})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            )),
        _logger = logger ?? Logger();

  final Dio _dio;
  final Logger _logger;

  /// Produce an embedding for [text] using [backend].
  ///
  /// Returns `null` if the provider key is missing or the request
  /// fails — callers should treat null as "retrieval unavailable" and
  /// fall back to a non-RAG prompt.
  Future<List<double>?> embed({
    required String text,
    required EmbeddingBackend backend,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty || text.trim().isEmpty) return null;
    try {
      switch (backend) {
        case EmbeddingBackend.wangchanberta:
          return await _embedWangchanBerta(text, apiKey);
        case EmbeddingBackend.openai:
          return await _embedOpenAi(text, apiKey);
      }
    } catch (e) {
      _logger.w('Embedding request failed', error: e);
      return null;
    }
  }

  /// WangchanBERTa embeddings via HuggingFace feature-extraction pipeline.
  /// Model: `airesearch/wangchanberta-base-att-spm-uncased`.
  ///
  /// HF returns a nested `[1, seq_len, hidden_dim]` tensor. We mean-pool
  /// over the sequence dimension to get a single 768-dim vector.
  Future<List<double>> _embedWangchanBerta(
      String text, String apiKey) async {
    final resp = await _dio.post<dynamic>(
      'https://api-inference.huggingface.co/pipeline/feature-extraction/'
      'airesearch/wangchanberta-base-att-spm-uncased',
      data: {
        'inputs': text,
        'options': {'wait_for_model': true},
      },
      options: Options(headers: {
        'authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      }),
    );
    final raw = resp.data;
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('Unexpected HuggingFace response shape');
    }
    // Some HF deployments return [batch, seq, hidden]; others [seq, hidden].
    final first = raw.first;
    final List<dynamic> seq = first is List && first.isNotEmpty && first.first is List
        ? first.cast<dynamic>()
        : raw.cast<dynamic>();
    if (seq.isEmpty || seq.first is! List) {
      throw const FormatException('Empty embedding sequence');
    }
    final hiddenDim = (seq.first as List).length;
    final pooled = List<double>.filled(hiddenDim, 0.0);
    for (final row in seq) {
      final r = row as List;
      for (var i = 0; i < hiddenDim; i++) {
        pooled[i] += (r[i] as num).toDouble();
      }
    }
    for (var i = 0; i < hiddenDim; i++) {
      pooled[i] /= seq.length;
    }
    return _normalize(pooled);
  }

  /// OpenAI `text-embedding-3-small` (1536-dim).
  Future<List<double>> _embedOpenAi(String text, String apiKey) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/embeddings',
      data: {
        'input': text,
        'model': 'text-embedding-3-small',
      },
      options: Options(headers: {
        'authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      }),
    );
    final list = resp.data?['data'] as List?;
    final data = (list == null || list.isEmpty)
        ? null
        : list.first as Map<String, dynamic>?;
    final embedding = (data?['embedding'] as List?)?.cast<num>();
    if (embedding == null) {
      throw const FormatException('Missing embedding in OpenAI response');
    }
    return _normalize(embedding.map((n) => n.toDouble()).toList());
  }

  /// L2-normalize so cosine similarity is just a dot product.
  static List<double> _normalize(List<double> v) {
    var sumSq = 0.0;
    for (final x in v) {
      sumSq += x * x;
    }
    final norm = sumSq <= 0 ? 1.0 : math.sqrt(sumSq);
    return [for (final x in v) x / norm];
  }
}
