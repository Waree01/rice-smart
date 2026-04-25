import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/env.dart';
import '../../../core/services/multimodal_vision_service.dart';
import '../../../core/theme/app_colors.dart';

/// Button + inline panel that asks a cloud vision LLM for a second
/// opinion on the image. Kept as an opt-in action so the default on-
/// device path stays privacy-preserving — a photo only leaves the
/// device when the farmer explicitly taps "ถามผู้เชี่ยวชาญคลาวด์".
class CloudSecondOpinion extends ConsumerStatefulWidget {
  final String imagePath;
  final bool isPest;
  const CloudSecondOpinion({
    super.key,
    required this.imagePath,
    this.isPest = false,
  });

  @override
  ConsumerState<CloudSecondOpinion> createState() => _CloudSecondOpinionState();
}

class _CloudSecondOpinionState extends ConsumerState<CloudSecondOpinion> {
  final _service = MultimodalVisionService();
  CloudVisionResult? _result;
  String? _error;
  bool _loading = false;
  String _provider = 'claude';

  static const _providers = {
    'claude': 'Claude',
    'gemini': 'Gemini',
  };

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiKey =
          _provider == 'claude' ? Env.claudeApiKey : Env.geminiApiKey;
      final result = widget.isPest
          ? await _service.analyzePest(
              imagePath: widget.imagePath,
              provider: _provider,
              apiKey: apiKey,
            )
          : await _service.analyzeDisease(
              imagePath: widget.imagePath,
              provider: _provider,
              apiKey: apiKey,
            );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return Card(
        color: AppColors.info.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_done, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    'ผู้เชี่ยวชาญคลาวด์ (${_providers[_result!.provider] ?? _result!.provider})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MarkdownBody(data: _result!.text, selectable: true),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ไม่แน่ใจผลการวินิจฉัย?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'ขอความเห็นที่สองจาก LLM บนคลาวด์ — ภาพจะถูกส่งออกนอกเครื่องเฉพาะเมื่อคุณกดปุ่มนี้',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                DropdownButton<String>(
                  value: _provider,
                  items: [
                    for (final entry in _providers.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (v) => setState(() => _provider = v ?? 'claude'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _run,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('ถามคลาวด์'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
