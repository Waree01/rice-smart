import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/features/yield_prediction/services/yield_prediction_service.dart';

void main() {
  final service = YieldPredictionService();

  group('YieldPredictionService.predict', () {
    test('optimal conditions produce near-baseline yield', () {
      final pred = service.predict(
        cumulativeGdd: YieldPredictionService.optimalCumGdd,
        daysSinceTransplant: 110,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 1400,
        farmSizeRai: 10,
      );
      // Expect within ±15% of the baseline at the optimum.
      expect(pred.tonnesPerRai,
          closeTo(YieldPredictionService.baselineTonnesPerRai, 0.11));
      expect(pred.confidence, greaterThan(0.8));
    });

    test('disease incidents reduce yield monotonically', () {
      final noDisease = service
          .predict(
            cumulativeGdd: 2400,
            daysSinceTransplant: 100,
            diseaseIncidents: 0,
            pestIncidents: 0,
            rainfallMm: 1400,
            farmSizeRai: 10,
          )
          .tonnesPerRai;
      final someDisease = service
          .predict(
            cumulativeGdd: 2400,
            daysSinceTransplant: 100,
            diseaseIncidents: 5,
            pestIncidents: 0,
            rainfallMm: 1400,
            farmSizeRai: 10,
          )
          .tonnesPerRai;
      expect(someDisease, lessThan(noDisease));
    });

    test('drought rainfall drops yield', () {
      final dry = service.predict(
        cumulativeGdd: 2000,
        daysSinceTransplant: 90,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 300,
        farmSizeRai: 10,
      );
      final wet = service.predict(
        cumulativeGdd: 2000,
        daysSinceTransplant: 90,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 1400,
        farmSizeRai: 10,
      );
      expect(dry.tonnesPerRai, lessThan(wet.tonnesPerRai));
    });

    test('totalTonnes scales linearly with farm size', () {
      final small = service.predict(
        cumulativeGdd: 2400,
        daysSinceTransplant: 100,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 1400,
        farmSizeRai: 5,
      );
      final big = service.predict(
        cumulativeGdd: 2400,
        daysSinceTransplant: 100,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 1400,
        farmSizeRai: 50,
      );
      expect(big.totalTonnes / small.totalTonnes, closeTo(10, 1e-6));
    });

    test('growth stage advances with days since transplant', () {
      final early = service.predict(
        cumulativeGdd: 300,
        daysSinceTransplant: 10,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 100,
        farmSizeRai: 10,
      );
      final late = service.predict(
        cumulativeGdd: 2600,
        daysSinceTransplant: 120,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 1500,
        farmSizeRai: 10,
      );
      expect(early.stage, GrowthStage.seedling);
      expect(late.stage, GrowthStage.maturity);
      expect(late.confidence, greaterThan(early.confidence));
    });
  });

  group('YieldPredictionService.projection', () {
    test('returns N+1 points for N weeks ahead', () {
      final proj = service.projection(
        cumulativeGdd: 1500,
        daysSinceTransplant: 60,
        diseaseIncidents: 0,
        pestIncidents: 0,
        rainfallMm: 800,
        farmSizeRai: 10,
        weeksAhead: 6,
      );
      expect(proj.length, 7);
    });
  });
}
