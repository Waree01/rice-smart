import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Severity band returned by the disease classifier.
enum DiseaseSeverity { low, medium, high, critical }

/// Classifier output for a single image inference.
class DiseaseResult {
  /// Localized Thai disease name, e.g. "โรคไหม้".
  final String diseaseName;

  /// English common name, e.g. "Rice Blast".
  final String diseaseNameEn;

  /// Model confidence in [0.0, 1.0].
  final double confidence;

  final DiseaseSeverity severity;

  /// Short treatment recommendation (Thai).
  final String recommendation;

  /// Longer explanation drawn from the knowledge base.
  final String? details;

  /// Local path to the captured image.
  final String? imagePath;

  /// Wall-clock timestamp of the inference.
  final DateTime detectedAt;

  const DiseaseResult({
    required this.diseaseName,
    required this.diseaseNameEn,
    required this.confidence,
    required this.severity,
    required this.recommendation,
    required this.detectedAt,
    this.details,
    this.imagePath,
  });

  /// Colour token for the severity badge.
  Color get severityColor {
    switch (severity) {
      case DiseaseSeverity.low:
        return AppColors.diseaseLow;
      case DiseaseSeverity.medium:
        return AppColors.diseaseMedium;
      case DiseaseSeverity.high:
        return AppColors.diseaseHigh;
      case DiseaseSeverity.critical:
        return AppColors.diseaseCritical;
    }
  }

  /// Thai label for the severity band.
  String get severityLabelTh {
    switch (severity) {
      case DiseaseSeverity.low:
        return 'ระดับเล็กน้อย';
      case DiseaseSeverity.medium:
        return 'ระดับปานกลาง';
      case DiseaseSeverity.high:
        return 'ระดับรุนแรง';
      case DiseaseSeverity.critical:
        return 'ระดับวิกฤต';
    }
  }
}
