import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/env.dart';
import '../../../core/services/benchmark_runner.dart';
import '../../../core/services/llm_gateway.dart';
import '../../../core/theme/app_colors.dart';
import '../../chatbot/providers/chatbot_providers.dart';

/// Developer / thesis screen: runs every benchmark question against
/// every configured LLM provider and tabulates the results.
class BenchmarkScreen extends ConsumerStatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  ConsumerState<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends ConsumerState<BenchmarkScreen> {
  final Set<String> _selectedProviders = {
    for (final p in LlmGateway.providers) p.id,
  };
  bool _running = false;
  double _progress = 0;
  List<BenchmarkResult> _results = [];
  Map<String, ProviderSummary> _summary = {};
  List<BenchmarkQuestion> _questions = [];

  Future<void> _run() async {
    final runner = BenchmarkRunner(gateway: ref.read(llmGatewayProvider));
    setState(() {
      _running = true;
      _progress = 0;
      _results = [];
      _summary = {};
    });
    try {
      _questions = await runner.loadQuestions();
      final results = await runner.run(
        questions: _questions,
        providers: _selectedProviders.toList(),
        apiKeys: Env.providerKeys,
        onProgress: (done, total) {
          setState(() => _progress = total == 0 ? 0 : done / total);
        },
      );
      setState(() {
        _results = results;
        _summary = runner.summarize(results);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เบนช์มาร์กล้มเหลว: $e')),
      );
    } finally {
      setState(() => _running = false);
    }
  }

  Future<void> _copyCsv() async {
    final runner = BenchmarkRunner(gateway: ref.read(llmGatewayProvider));
    final csv = runner.toCsv(_results);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอก CSV แล้ว — วางลง Excel ได้เลย')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Benchmark'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'เปรียบเทียบคำตอบของ LLM แต่ละตัวกับชุดคำถามเกษตรภาษาไทย ใช้สำหรับงานวิจัย thesis',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('เลือก provider ที่จะวัด',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  for (final p in LlmGateway.providers)
                    CheckboxListTile(
                      value: _selectedProviders.contains(p.id),
                      title: Text(p.displayName),
                      subtitle: Text(p.model),
                      dense: true,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedProviders.add(p.id);
                          } else {
                            _selectedProviders.remove(p.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_running) LinearProgressIndicator(value: _progress),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _running ||
                          _selectedProviders.isEmpty
                      ? null
                      : _run,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('เริ่มเบนช์มาร์ก'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _results.isEmpty ? null : _copyCsv,
                icon: const Icon(Icons.copy),
                label: const Text('Copy CSV'),
              ),
            ],
          ),
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SummaryTable(summary: _summary),
            const SizedBox(height: 16),
            Text('รายละเอียดคำตอบ (${_results.length} แถว)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final r in _results) _ResultTile(result: r),
          ],
        ],
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  final Map<String, ProviderSummary> summary;
  const _SummaryTable({required this.summary});

  @override
  Widget build(BuildContext context) {
    final rows = summary.values.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('สรุปต่อ provider',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DataTable(
              columns: const [
                DataColumn(label: Text('Provider')),
                DataColumn(label: Text('Runs')),
                DataColumn(label: Text('Err'), numeric: true),
                DataColumn(label: Text('Latency'), numeric: true),
                DataColumn(label: Text('Coverage'), numeric: true),
              ],
              rows: [
                for (final s in rows)
                  DataRow(cells: [
                    DataCell(Text(s.provider)),
                    DataCell(Text('${s.runs}')),
                    DataCell(Text('${s.errorCount}')),
                    DataCell(Text('${s.meanLatencyMs.toStringAsFixed(0)} ms')),
                    DataCell(Text(
                        '${(s.meanCoverage * 100).toStringAsFixed(0)}%')),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final BenchmarkResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text('[${result.provider}] ${result.questionId}'),
        subtitle: Text(
          'coverage ${(result.coverage * 100).toStringAsFixed(0)}% · '
          '${result.latencyMs} ms · ${result.keywordHits}/${result.keywordTotal} keywords',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(result.answer),
          ),
        ],
      ),
    );
  }
}
