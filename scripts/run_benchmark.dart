/// Standalone CLI runner for the LLM benchmark.
///
/// Use when you want benchmark results without booting the Flutter UI
/// (e.g. for thesis data collection or CI). Reads the same .env file
/// the app does, runs every provider whose key is set, and dumps a CSV
/// to stdout.
///
/// Usage (from project root):
///
///   dart run scripts/run_benchmark.dart                       # all providers
///   dart run scripts/run_benchmark.dart gemini                # one provider
///   dart run scripts/run_benchmark.dart gemini claude > out.csv
///
/// Requires `flutter pub get` to have run first so the package
/// dependencies are resolved.
library;

import 'dart:convert';
import 'dart:io';

import 'package:rice_smart/core/services/benchmark_runner.dart';
import 'package:rice_smart/core/services/llm_gateway.dart';

void main(List<String> args) async {
  final env = _loadDotEnv();
  final apiKeys = <String, String>{
    'claude': env['CLAUDE_API_KEY'] ?? '',
    'gpt': env['OPENAI_API_KEY'] ?? '',
    'gemini': env['GEMINI_API_KEY'] ?? '',
    'typhoon': env['TYPHOON_API_KEY'] ?? '',
  };

  final allProviders = ['typhoon', 'claude', 'gemini', 'gpt'];
  final selected = args.isEmpty
      ? allProviders.where((p) => (apiKeys[p] ?? '').isNotEmpty).toList()
      : args;

  if (selected.isEmpty) {
    stderr.writeln('No providers configured — populate .env first.');
    exit(1);
  }
  stderr.writeln('Running benchmark on: ${selected.join(", ")}');

  final runner = BenchmarkRunner(gateway: LlmGateway());
  final questions = await _loadQuestionsLocally();
  stderr.writeln('Loaded ${questions.length} questions');

  final results = await runner.run(
    questions: questions,
    providers: selected,
    apiKeys: apiKeys,
    onProgress: (done, total) {
      stderr.writeln('  [$done/$total]');
    },
  );

  // CSV to stdout
  stdout.writeln(runner.toCsv(results));

  // Summary to stderr (so CSV is clean)
  final summary = runner.summarize(results);
  stderr.writeln('\n── Summary ─────────────────────────────────');
  stderr.writeln('provider     | runs | err | latency  | coverage');
  for (final s in summary.values) {
    final p = s.provider.padRight(12);
    final r = '${s.runs}'.padLeft(4);
    final e = '${s.errorCount}'.padLeft(3);
    final l = '${s.meanLatencyMs.toStringAsFixed(0)} ms'.padLeft(8);
    final c = '${(s.meanCoverage * 100).toStringAsFixed(0)}%'.padLeft(7);
    stderr.writeln('$p | $r | $e | $l | $c');
  }
}

/// Tiny .env parser — avoids depending on flutter_dotenv at the CLI
/// since flutter_dotenv expects an asset bundle context.
Map<String, String> _loadDotEnv() {
  final candidates = ['.env', '.env.example'];
  for (final name in candidates) {
    final f = File(name);
    if (!f.existsSync()) continue;
    final out = <String, String>{};
    for (final raw in f.readAsLinesSync()) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq < 0) continue;
      out[line.substring(0, eq).trim()] =
          line.substring(eq + 1).trim().replaceAll(RegExp(r'^"|"$'), '');
    }
    return out;
  }
  return const {};
}

/// Load benchmark_questions.json directly from disk (no rootBundle).
Future<List<BenchmarkQuestion>> _loadQuestionsLocally() async {
  final raw =
      File('assets/knowledge_base/benchmark_questions.json').readAsStringSync();
  final json_ = json.decode(raw) as Map<String, dynamic>;
  final list = (json_['questions'] as List).cast<Map<String, dynamic>>();
  return list.map(BenchmarkQuestion.fromJson).toList();
}
