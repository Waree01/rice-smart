import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/disease_providers.dart';
import '../widgets/disease_result_card.dart';

/// Rice Disease Detection Screen.
///
/// Camera/gallery → on-device inference → result card. The inference is
/// handled by [DiseaseInferenceService] (currently a mock, wired to the
/// real knowledge base). Users can re-shoot or hand the diagnosis over
/// to Pasadee for follow-up advice.
class DiseaseDetectionScreen extends ConsumerWidget {
  const DiseaseDetectionScreen({super.key});

  Future<void> _capture(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      await ref
          .read(diseaseDetectionControllerProvider.notifier)
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
    final state = ref.watch(diseaseDetectionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('วินิจฉัยโรคข้าว'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (state.valueOrNull != null)
            IconButton(
              tooltip: 'เริ่มใหม่',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref
                  .read(diseaseDetectionControllerProvider.notifier)
                  .reset(),
            ),
        ],
      ),
      body: state.when(
        data: (result) {
          if (result == null) return const _EmptyState();
          return DiseaseResultCard(
            result: result,
            onRetry: () => ref
                .read(diseaseDetectionControllerProvider.notifier)
                .reset(),
            onAskPasadee: () => context.push(
              '/chatbot',
              extra: 'จากภาพที่ถ่าย AI วินิจฉัยว่าอาจเป็น "${result.diseaseName}" '
                  '(ความมั่นใจ ${(result.confidence * 100).toStringAsFixed(0)}%) '
                  'ช่วยแนะนำวิธีจัดการแบบละเอียดให้หน่อยครับ',
            ),
          );
        },
        loading: () => const _AnalyzingView(),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref
              .read(diseaseDetectionControllerProvider.notifier)
              .reset(),
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
            Icon(Icons.local_florist, size: 80, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'ถ่ายภาพใบข้าวที่สงสัยว่าเป็นโรค',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'AI จะวิเคราะห์โรคและแนะนำวิธีจัดการ\n(การประมวลผลเกิดบนเครื่อง ไม่ส่งภาพออกนอก)',
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
          Text('กำลังวิเคราะห์ภาพด้วย AI...'),
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
