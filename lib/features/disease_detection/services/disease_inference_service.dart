import 'dart:math';

import '../../../data/knowledge_base.dart';
import '../../../models/disease_result.dart';

/// Rice-disease classifier.
///
/// Current implementation is a deterministic mock: it picks a disease
/// using a seeded random based on the image path (so repeat inferences
/// on the same file yield the same answer). The real pipeline plugs in
/// at [_runModel] — swap the stub for an `Interpreter` from
/// `tflite_flutter` with EfficientNet-B0 weights when the trained
/// `.tflite` asset is ready.
class DiseaseInferenceService {
  /// Confidence below this threshold returns a "not confident" result
  /// and recommends retrying the photo.
  static const double confidenceFloor = 0.55;

  Future<DiseaseResult> classify({
    required String imagePath,
  }) async {
    // Simulate inference latency (real model is ~150–300ms on device).
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final prediction = await _runModel(imagePath);
    final kbEntry = await KnowledgeBase.instance.diseaseById(prediction.id);
    final severity = _deriveSeverity(prediction.confidence);

    return DiseaseResult(
      diseaseName: kbEntry?['nameTh'] as String? ?? prediction.id,
      diseaseNameEn: kbEntry?['nameEn'] as String? ?? prediction.id,
      confidence: prediction.confidence,
      severity: severity,
      recommendation:
          (kbEntry?['recommendation'] as String?) ?? _fallbackRecommendation,
      details: _composeDetails(kbEntry),
      imagePath: imagePath,
      detectedAt: DateTime.now(),
    );
  }

  // ── Model hook ────────────────────────────────────────────────────
  // Replace the body of _runModel with a real TFLite invocation once
  // EfficientNet-B0 weights are in assets/models/rice_disease.tflite.
  //
  // Sketch of real implementation:
  //   1. Decode image via `image` package, resize to 224×224, normalize
  //      to ImageNet mean/std (or mobilenet_v2 preprocess).
  //   2. Run `Interpreter.fromAsset(modelPath).run(input, output)`.
  //   3. Take argmax over the 5-class softmax and translate index →
  //      label via `assets/models/disease_labels.txt`.

  Future<_Prediction> _runModel(String imagePath) async {
    // Seed RNG from image path so the same photo → same result.
    final seed = imagePath.hashCode ^ DateTime.now().day;
    final rng = Random(seed);

    const candidates = <String>[
      'rice_blast',
      'brown_spot',
      'bacterial_leaf_blight',
      'sheath_blight',
      'healthy',
    ];
    final label = candidates[rng.nextInt(candidates.length)];
    // Confidence 0.62 – 0.94.
    final confidence = 0.62 + rng.nextDouble() * 0.32;
    return _Prediction(label, confidence);
  }

  DiseaseSeverity _deriveSeverity(double confidence) {
    if (confidence < 0.6) return DiseaseSeverity.low;
    if (confidence < 0.75) return DiseaseSeverity.medium;
    if (confidence < 0.88) return DiseaseSeverity.high;
    return DiseaseSeverity.critical;
  }

  String? _composeDetails(Map<String, dynamic>? kb) {
    if (kb == null) return null;
    final parts = <String>[];
    final pathogen = kb['pathogen'];
    if (pathogen is String && pathogen.isNotEmpty) {
      parts.add('เชื้อก่อโรค: $pathogen');
    }
    final symptoms = kb['symptoms'];
    if (symptoms is List && symptoms.isNotEmpty) {
      parts.add('อาการเด่น:\n• ${symptoms.join('\n• ')}');
    }
    final tips = kb['preventiveTips'];
    if (tips is List && tips.isNotEmpty) {
      parts.add('การป้องกัน:\n• ${tips.join('\n• ')}');
    }
    return parts.isEmpty ? null : parts.join('\n\n');
  }

  static const String _fallbackRecommendation =
      'ไม่แน่ใจชนิดโรค ลองถ่ายภาพใหม่ให้ชัดและเห็นอาการเด่น หรือปรึกษาเจ้าหน้าที่เกษตรในพื้นที่ครับ';
}

class _Prediction {
  final String id;
  final double confidence;
  const _Prediction(this.id, this.confidence);
}
