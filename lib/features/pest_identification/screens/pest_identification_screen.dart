import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/pest_providers.dart';
import '../widgets/pest_result_card.dart';

/// Pest Identification Screen — YOLO-style on-device detection.
class PestIdentificationScreen extends ConsumerWidget {
  const PestIdentificationScreen({super.key});

  Future<void> _capture(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      await ref
          .read(pestDetectionControllerProvider.notifier)
          .analyze(file.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดกล้องไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pestDetectionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบุศัตรูพืช'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        actions: [
          if (state.valueOrNull != null)
            IconButton(
              tooltip: 'เริ่มใหม่',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(pestDetectionControllerProvider.notifier).reset(),
            ),
        ],
      ),
      body: state.when(
        data: (result) {
          if (result == null) return const _EmptyState();
          final primaryName = result.primary?.nameTh ?? 'แมลงที่พบ';
          return PestResultCard(
            result: result,
            onRetry: () =>
                ref.read(pestDetectionControllerProvider.notifier).reset(),
            onAskPasadee: () => context.push(
              '/chatbot',
              extra: 'ระบบตรวจพบ "$primaryName" ในแปลงผม '
                  'ช่วยแนะนำวิธีจัดการที่เหมาะกับระยะการเจริญเติบโตของข้าวหน่อยครับ',
            ),
          );
        },
        loading: () => const _AnalyzingView(),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () =>
              ref.read(pestDetectionControllerProvider.notifier).reset(),
        ),
      ),
      bottomNavigationBar: state.maybeWhen(
        data: (r) => r == null ? _captureBar(context, ref) : null,
        orElse: () => null,
      ),
    );
  }

  Widget _captureBar(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _capture(context, ref, ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('จากคลัง'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _capture(context, ref, ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('ถ่ายรูป'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report, size: 80, color: AppColors.warning),
            SizedBox(height: 16),
            Text(
              'ถ่ายภาพแมลงหรือรอยกัดในแปลง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'AI ระบุชนิดศัตรูพืชและแนะนำวิธีจัดการ\n(ใช้โมเดล YOLO ประมวลผลบนเครื่อง)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  const _AnalyzingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('กำลังค้นหาศัตรูพืชในภาพ...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}
