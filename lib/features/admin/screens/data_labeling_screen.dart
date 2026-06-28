import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/canonical_labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/review_sample.dart';
import '../providers/admin_providers.dart';

/// Active-learning labeller (mockup screen 9).
///
/// Walks the admin through each pending low-confidence sample. Confirming
/// or correcting the label feeds the corrected (image, label) pair back
/// as training data for the next model revision.
class DataLabelingScreen extends ConsumerStatefulWidget {
  const DataLabelingScreen({super.key});

  @override
  ConsumerState<DataLabelingScreen> createState() => _DataLabelingScreenState();
}

class _DataLabelingScreenState extends ConsumerState<DataLabelingScreen> {
  List<ReviewSample> _queue = [];
  int _index = 0;
  int _total = 0;
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final queue = await ref.read(reviewQueueServiceProvider).pending();
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _total = queue.length;
      _index = 0;
      _loading = false;
      _selected = queue.isEmpty ? null : queue.first.aiGuessId;
    });
  }

  ReviewSample? get _current => _index < _queue.length ? _queue[_index] : null;

  void _advance() {
    setState(() {
      _index++;
      _selected = _current?.aiGuessId;
    });
  }

  Future<void> _confirm() async {
    final sample = _current;
    if (sample == null || _selected == null) return;
    await ref.read(reviewQueueServiceProvider).label(sample.id, _selected!);
    refreshAdmin(ref);
    _advance();
  }

  Future<void> _skip() async {
    final sample = _current;
    if (sample == null) return;
    await ref.read(reviewQueueServiceProvider).skip(sample.id);
    refreshAdmin(ref);
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final sample = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดป้ายข้อมูล'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          if (sample != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_index + 1}/$_total',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : sample == null
              ? _Done(labeled: _total)
              : _LabelingBody(
                  sample: sample,
                  selected: _selected,
                  onSelect: (id) => setState(() => _selected = id),
                  onSkip: _skip,
                  onConfirm: _confirm,
                ),
    );
  }
}

class _LabelingBody extends StatelessWidget {
  final ReviewSample sample;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onSkip;
  final VoidCallback onConfirm;

  const _LabelingBody({
    required this.sample,
    required this.selected,
    required this.onSelect,
    required this.onSkip,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final labels = CanonicalLabels.forKind(isPest: sample.isPest);
    final path = sample.imagePath;
    final hasImage = path != null && File(path).existsSync();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImage
                  ? Image.file(
                      File(path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 200,
                      color: const Color(0xFF173404),
                      alignment: Alignment.center,
                      child: Icon(
                        sample.isPest ? Icons.bug_report : Icons.local_florist,
                        size: 56,
                        color: const Color(0xFFC0DD97),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  const TextSpan(text: 'AI ทาย: '),
                  TextSpan(
                    text:
                        '${sample.aiGuessTh} (${(sample.confidence * 100).round()}%)',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ป้ายที่ถูกต้อง',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in labels)
                  _LabelChip(
                    label: l.nameTh,
                    selected: selected == l.id,
                    onTap: () => onSelect(l.id),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.close),
                    label: const Text('ข้าม'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: selected == null ? null : onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LabelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[800],
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  final int labeled;
  const _Done({required this.labeled});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              labeled == 0 ? 'ไม่มีภาพรอติดป้าย' : 'ติดป้ายครบทุกภาพแล้ว 🎉',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'ข้อมูลที่ติดป้ายจะใช้ฝึกโมเดลรุ่นถัดไป',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/admin'),
              child: const Text('กลับแดชบอร์ด'),
            ),
          ],
        ),
      ),
    );
  }
}
