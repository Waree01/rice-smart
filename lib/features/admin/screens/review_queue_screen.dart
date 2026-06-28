import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/review_sample.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_bottom_nav.dart';

/// Review queue (mockup screen 8) — images the classifier was unsure
/// about, waiting for a human label. Tapping "เริ่มตรวจสอบ" opens the
/// active-learning labeller.
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingReviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('คิวรอตรวจสอบ'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('โหลดคิวไม่สำเร็จ: $e')),
        data: (samples) {
          if (samples.isEmpty) {
            return const _EmptyQueue();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ภาพจากผู้ใช้ที่ AI ไม่มั่นใจ (${samples.length})',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: samples.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _QueueTile(sample: samples[i]),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => context.go('/admin/labeling'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('เริ่มตรวจสอบ'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNav(current: 1),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final ReviewSample sample;
  const _QueueTile({required this.sample});

  @override
  Widget build(BuildContext context) {
    final isPest = sample.isPest;
    final tint = isPest ? AppColors.warning : AppColors.error;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: _Thumb(sample: sample, tint: tint),
      title: Text(
        '${sample.aiGuessTh}?',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('มั่นใจ ${(sample.confidence * 100).round()}%'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.adminAmber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'รอตรวจ',
          style: TextStyle(
            color: AppColors.adminAmber,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final ReviewSample sample;
  final Color tint;
  const _Thumb({required this.sample, required this.tint});

  @override
  Widget build(BuildContext context) {
    final path = sample.imagePath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        sample.isPest ? Icons.bug_report : Icons.local_florist,
        color: tint,
        size: 20,
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'ไม่มีภาพรอตรวจสอบ\nAI มั่นใจกับทุกภาพล่าสุดแล้ว',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
