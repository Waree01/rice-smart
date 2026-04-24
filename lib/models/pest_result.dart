/// A single detection box from the pest YOLO model.
class PestDetection {
  /// English common name, e.g. "Brown planthopper".
  final String nameEn;

  /// Thai label, e.g. "เพลี้ยกระโดดสีน้ำตาล".
  final String nameTh;

  /// Model confidence in [0.0, 1.0].
  final double confidence;

  /// Normalized bounding box [left, top, right, bottom] in [0.0, 1.0]
  /// image coordinates.
  final List<double> bbox;

  const PestDetection({
    required this.nameEn,
    required this.nameTh,
    required this.confidence,
    required this.bbox,
  });
}

/// Aggregated result from one pest inference run.
class PestResult {
  final List<PestDetection> detections;
  final String? imagePath;
  final DateTime detectedAt;

  /// Top-line recommendation (Thai) built from the primary detection.
  final String recommendation;

  const PestResult({
    required this.detections,
    required this.recommendation,
    required this.detectedAt,
    this.imagePath,
  });

  PestDetection? get primary =>
      detections.isEmpty ? null : detections.first;

  bool get isEmpty => detections.isEmpty;
}
