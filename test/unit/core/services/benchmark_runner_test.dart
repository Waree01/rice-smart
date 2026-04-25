import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/benchmark_runner.dart';

void main() {
  group('BenchmarkQuestion', () {
    test('BenchmarkQuestion can be instantiated', () {
      const question = BenchmarkQuestion(
        id: 'q1',
        category: 'disease',
        question: 'What is this disease?',
        expectedKeywords: ['disease', 'treatment'],
      );

      expect(question.id, 'q1');
      expect(question.category, 'disease');
      expect(question.expectedKeywords.length, 2);
    });

    test('BenchmarkQuestion.fromJson parses JSON correctly', () {
      final json = {
        'id': 'q1',
        'category': 'disease',
        'question': 'Test',
        'expected_keywords': ['a', 'b'],
      };

      final question = BenchmarkQuestion.fromJson(json);
      expect(question.id, 'q1');
      expect(question.expectedKeywords, ['a', 'b']);
    });

    test('BenchmarkQuestion.fromJson handles missing keywords', () {
      final json = {
        'id': 'q1',
        'category': 'disease',
        'question': 'Test',
      };

      final question = BenchmarkQuestion.fromJson(json);
      expect(question.expectedKeywords, isEmpty);
    });
  });

  group('BenchmarkResult', () {
    test('BenchmarkResult stores all fields', () {
      const result = BenchmarkResult(
        questionId: 'q1',
        category: 'disease',
        provider: 'claude',
        answer: 'Test answer',
        latencyMs: 100,
        keywordHits: 2,
        keywordTotal: 3,
      );

      expect(result.questionId, 'q1');
      expect(result.provider, 'claude');
      expect(result.latencyMs, 100);
    });

    test('coverage getter calculates keyword hit ratio', () {
      const result = BenchmarkResult(
        questionId: 'q1',
        category: 'disease',
        provider: 'claude',
        answer: 'test',
        latencyMs: 100,
        keywordHits: 2,
        keywordTotal: 4,
      );

      expect(result.coverage, closeTo(0.5, 0.01));
    });

    test('coverage is 0 when keywordTotal is 0', () {
      const result = BenchmarkResult(
        questionId: 'q1',
        category: 'disease',
        provider: 'claude',
        answer: 'test',
        latencyMs: 100,
        keywordHits: 0,
        keywordTotal: 0,
      );

      expect(result.coverage, 0.0);
    });

    test('toCsvRow escapes quotes in answer', () {
      const result = BenchmarkResult(
        questionId: 'q1',
        category: 'disease',
        provider: 'claude',
        answer: 'Answer with "quotes"',
        latencyMs: 100,
        keywordHits: 1,
        keywordTotal: 2,
      );

      final csv = result.toCsvRow();
      expect(csv, contains('""'));
    });

    test('toCsvRow includes all fields', () {
      const result = BenchmarkResult(
        questionId: 'q1',
        category: 'disease',
        provider: 'claude',
        answer: 'test answer',
        latencyMs: 100,
        keywordHits: 1,
        keywordTotal: 2,
      );

      final csv = result.toCsvRow();
      expect(csv, contains('q1'));
      expect(csv, contains('claude'));
      expect(csv, contains('100'));
    });

    test('csvHeader is constant', () {
      expect(BenchmarkResult.csvHeader, contains('question_id'));
      expect(BenchmarkResult.csvHeader, contains('provider'));
    });
  });

  group('ProviderSummary', () {
    test('ProviderSummary.from aggregates results correctly', () {
      final results = [
        const BenchmarkResult(
          questionId: 'q1',
          category: 'disease',
          provider: 'claude',
          answer: 'Response 1',
          latencyMs: 100,
          keywordHits: 2,
          keywordTotal: 3,
        ),
        const BenchmarkResult(
          questionId: 'q2',
          category: 'pest',
          provider: 'claude',
          answer: 'Response 2',
          latencyMs: 150,
          keywordHits: 3,
          keywordTotal: 3,
        ),
      ];

      final summary = ProviderSummary.from('claude', results);

      expect(summary.provider, 'claude');
      expect(summary.runs, 2);
      expect(summary.errorCount, 0);
      expect(summary.meanLatencyMs, closeTo(125.0, 0.1));
      expect(summary.meanCoverage, closeTo(0.833, 0.01));
    });

    test('ProviderSummary.from handles error results', () {
      final results = [
        const BenchmarkResult(
          questionId: 'q1',
          category: 'disease',
          provider: 'claude',
          answer: 'ERROR: timeout',
          latencyMs: 0,
          keywordHits: 0,
          keywordTotal: 2,
        ),
        const BenchmarkResult(
          questionId: 'q2',
          category: 'pest',
          provider: 'claude',
          answer: 'Valid response',
          latencyMs: 100,
          keywordHits: 1,
          keywordTotal: 2,
        ),
      ];

      final summary = ProviderSummary.from('claude', results);

      expect(summary.runs, 2);
      expect(summary.errorCount, 1);
      expect(summary.meanLatencyMs, 100.0);
    });

    test('ProviderSummary.from handles empty results list', () {
      final summary = ProviderSummary.from('claude', []);

      expect(summary.provider, 'claude');
      expect(summary.runs, 0);
      expect(summary.errorCount, 0);
      expect(summary.meanLatencyMs, 0.0);
      expect(summary.meanCoverage, 0.0);
    });
  });
}
