import 'package:logger/logger.dart';

import 'llm_gateway.dart';

// Note: this file is intentionally Flutter-free so it can run under a
// plain `dart run` for offline benchmarking. Question loading happens
// in the caller (UI uses rootBundle; CLI reads from File directly).

/// A single question from the thesis Q&A benchmark.
class BenchmarkQuestion {
  final String id;
  final String category;
  final String question;
  final List<String> expectedKeywords;
  const BenchmarkQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.expectedKeywords,
  });

  factory BenchmarkQuestion.fromJson(Map<String, dynamic> json) =>
      BenchmarkQuestion(
        id: json['id'] as String,
        category: json['category'] as String,
        question: json['question'] as String,
        expectedKeywords:
            ((json['expected_keywords'] as List?) ?? const []).cast<String>(),
      );
}

/// Result row — one (question × provider) pair.
class BenchmarkResult {
  final String questionId;
  final String category;
  final String provider;
  final String answer;
  final int latencyMs;
  final int keywordHits;
  final int keywordTotal;
  final double? score; // 0..1, filled if a rubric is applied

  const BenchmarkResult({
    required this.questionId,
    required this.category,
    required this.provider,
    required this.answer,
    required this.latencyMs,
    required this.keywordHits,
    required this.keywordTotal,
    this.score,
  });

  double get coverage => keywordTotal == 0 ? 0.0 : keywordHits / keywordTotal;

  /// Serialize to CSV — easy to paste into Excel / thesis tables.
  String toCsvRow() {
    final safeAnswer = answer.replaceAll('"', '""').replaceAll('\n', ' ');
    return '$questionId,$category,$provider,$latencyMs,'
        '$keywordHits,$keywordTotal,'
        '${coverage.toStringAsFixed(3)},'
        '"$safeAnswer"';
  }

  static const csvHeader =
      'question_id,category,provider,latency_ms,keyword_hits,keyword_total,coverage,answer';
}

/// Runs the benchmark — iterates all (question × provider) pairs and
/// records answers + metrics. Designed to be driven from a dev screen
/// or CI job.
class BenchmarkRunner {
  BenchmarkRunner({
    required LlmGateway gateway,
    Logger? logger,
  })  : _gateway = gateway,
        _logger = logger ?? Logger();

  final LlmGateway _gateway;
  final Logger _logger;

  /// Run [questions] across [providers] using [apiKeys]. Progress is
  /// streamed through [onProgress] (current, total).
  Future<List<BenchmarkResult>> run({
    required List<BenchmarkQuestion> questions,
    required List<String> providers,
    required Map<String, String> apiKeys,
    void Function(int done, int total)? onProgress,
  }) async {
    final results = <BenchmarkResult>[];
    final total = questions.length * providers.length;
    var done = 0;

    for (final q in questions) {
      for (final provider in providers) {
        final key = apiKeys[provider] ?? '';
        if (key.isEmpty) {
          _logger.d('Skip $provider (no key)');
          done++;
          onProgress?.call(done, total);
          continue;
        }
        try {
          final response = await _gateway.sendMessage(
            userMessage: q.question,
            preferredProvider: provider,
            apiKeys: {provider: key},
          );
          final hits = _countKeywordHits(response.content, q.expectedKeywords);
          results.add(
            BenchmarkResult(
              questionId: q.id,
              category: q.category,
              provider: response.provider,
              answer: response.content,
              latencyMs: response.latencyMs,
              keywordHits: hits,
              keywordTotal: q.expectedKeywords.length,
            ),
          );
        } catch (e) {
          _logger.w('Benchmark ${q.id} / $provider failed', error: e);
          results.add(
            BenchmarkResult(
              questionId: q.id,
              category: q.category,
              provider: provider,
              answer: 'ERROR: $e',
              latencyMs: 0,
              keywordHits: 0,
              keywordTotal: q.expectedKeywords.length,
            ),
          );
        }
        done++;
        onProgress?.call(done, total);
      }
    }
    return results;
  }

  /// Simple keyword-based scoring: count how many of the expected
  /// keywords appear in the answer (case-insensitive substring). Not a
  /// substitute for human evaluation but fine for quick triage.
  int _countKeywordHits(String answer, List<String> keywords) {
    final lower = answer.toLowerCase();
    var hits = 0;
    for (final kw in keywords) {
      if (lower.contains(kw.toLowerCase())) hits++;
    }
    return hits;
  }

  /// Aggregate per-provider summary (mean latency, mean coverage).
  Map<String, ProviderSummary> summarize(List<BenchmarkResult> results) {
    final byProvider = <String, List<BenchmarkResult>>{};
    for (final r in results) {
      byProvider.putIfAbsent(r.provider, () => []).add(r);
    }
    return {
      for (final entry in byProvider.entries)
        entry.key: ProviderSummary.from(entry.key, entry.value),
    };
  }

  String toCsv(List<BenchmarkResult> results) {
    final buf = StringBuffer(BenchmarkResult.csvHeader)..writeln();
    for (final r in results) {
      buf.writeln(r.toCsvRow());
    }
    return buf.toString();
  }
}

class ProviderSummary {
  final String provider;
  final int runs;
  final int errorCount;
  final double meanLatencyMs;
  final double meanCoverage;

  const ProviderSummary({
    required this.provider,
    required this.runs,
    required this.errorCount,
    required this.meanLatencyMs,
    required this.meanCoverage,
  });

  factory ProviderSummary.from(String provider, List<BenchmarkResult> rows) {
    if (rows.isEmpty) {
      return ProviderSummary(
        provider: provider,
        runs: 0,
        errorCount: 0,
        meanLatencyMs: 0,
        meanCoverage: 0,
      );
    }
    final errors = rows.where((r) => r.answer.startsWith('ERROR:')).length;
    final successRows =
        rows.where((r) => !r.answer.startsWith('ERROR:')).toList();
    final latency = successRows.isEmpty
        ? 0.0
        : successRows.fold<num>(0, (acc, r) => acc + r.latencyMs) /
            successRows.length;
    final cov = successRows.isEmpty
        ? 0.0
        : successRows.fold<double>(0.0, (acc, r) => acc + r.coverage) /
            successRows.length;
    return ProviderSummary(
      provider: provider,
      runs: rows.length,
      errorCount: errors,
      meanLatencyMs: latency.toDouble(),
      meanCoverage: cov,
    );
  }
}
