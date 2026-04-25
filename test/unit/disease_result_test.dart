import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/theme/app_colors.dart';
import 'package:rice_smart/models/disease_result.dart';

void main() {
  DiseaseResult make(DiseaseSeverity s) => DiseaseResult(
        diseaseName: 'x',
        diseaseNameEn: 'x',
        confidence: 0.8,
        severity: s,
        recommendation: '',
        detectedAt: DateTime.now(),
      );

  group('DiseaseResult', () {
    test('severity colour matches the palette', () {
      expect(make(DiseaseSeverity.low).severityColor, AppColors.diseaseLow);
      expect(
        make(DiseaseSeverity.medium).severityColor,
        AppColors.diseaseMedium,
      );
      expect(make(DiseaseSeverity.high).severityColor, AppColors.diseaseHigh);
      expect(
        make(DiseaseSeverity.critical).severityColor,
        AppColors.diseaseCritical,
      );
    });

    test('Thai severity label is populated for every band', () {
      for (final s in DiseaseSeverity.values) {
        expect(make(s).severityLabelTh, isNotEmpty);
      }
    });
  });
}
