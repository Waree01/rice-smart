import 'dart:math';

import '../../../data/knowledge_base.dart';
import '../../../models/pest_result.dart';

/// Rice-pest detector.
///
/// Mock-mode implementation that mimics a YOLOv5s-INT8 model (~3–4 MB).
/// Replace [_runModel] with a real interpreter call once the trained
/// `.tflite` file is in `assets/models/pest_yolov5s.tflite`.
class PestInferenceService {
  Future<PestResult> detect({required String imagePath}) async {
    await Future<void>.delayed(const Duration(milliseconds: 750));

    final detections = await _runModel(imagePath);
    String recommendation =
        'ไม่พบศัตรูพืชชัดเจน ลองถ่ายให้ใกล้ตัวแมลงมากขึ้นครับ';
    if (detections.isNotEmpty) {
      final top = detections.first;
      final kbEntry =
          await KnowledgeBase.instance.pestById(_toKbId(top.nameEn));
      recommendation = (kbEntry?['recommendation'] as String?) ??
          'พบ ${top.nameTh} ในแปลง ลองสำรวจรอบ ๆ กอเพิ่มเติมและจดบันทึกความเสียหายครับ';
    }

    return PestResult(
      detections: detections,
      recommendation: recommendation,
      imagePath: imagePath,
      detectedAt: DateTime.now(),
    );
  }

  // ── Model hook ────────────────────────────────────────────────────
  // Real implementation:
  //   1. Decode image, letterbox to 640×640.
  //   2. `Interpreter.fromAsset(...).runForMultipleInputs(...)`.
  //   3. Apply NMS (non-max suppression) at IoU=0.45, conf=0.35.
  //   4. Map class indices → labels via assets/models/pest_labels.txt.

  Future<List<PestDetection>> _runModel(String imagePath) async {
    final seed = imagePath.hashCode ^ DateTime.now().day;
    final rng = Random(seed);

    const catalog = <_PestEntry>[
      _PestEntry('Brown planthopper', 'เพลี้ยกระโดดสีน้ำตาล'),
      _PestEntry('Yellow stem borer', 'หนอนกอข้าว'),
      _PestEntry('Rice leaffolder', 'หนอนห่อใบข้าว'),
      _PestEntry('Rice bug', 'มวนเขียว'),
      _PestEntry('Golden apple snail', 'หอยเชอรี่'),
    ];

    // 0–3 random detections to mimic a real scene.
    final count = rng.nextInt(4);
    if (count == 0) return const [];

    final entries = [...catalog]..shuffle(rng);
    return List.generate(count, (i) {
      final e = entries[i];
      final confidence = 0.55 + rng.nextDouble() * 0.4;
      final left = rng.nextDouble() * 0.5;
      final top = rng.nextDouble() * 0.5;
      return PestDetection(
        nameEn: e.en,
        nameTh: e.th,
        confidence: confidence,
        bbox: [
          left,
          top,
          left + 0.25 + rng.nextDouble() * 0.2,
          top + 0.25 + rng.nextDouble() * 0.2,
        ],
      );
    })
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Map English common name → KB id.
  String _toKbId(String nameEn) {
    switch (nameEn) {
      case 'Brown planthopper':
        return 'brown_planthopper';
      case 'Yellow stem borer':
        return 'rice_stem_borer';
      case 'Rice leaffolder':
        return 'rice_leaffolder';
      case 'Rice bug':
        return 'rice_bug';
      case 'Golden apple snail':
        return 'golden_apple_snail';
      default:
        return '';
    }
  }
}

class _PestEntry {
  final String en;
  final String th;
  const _PestEntry(this.en, this.th);
}
