import 'dart:math' as math;

/// Stage in the rice-growth lifecycle expressed in days-after-seeding.
enum GrowthStage {
  seedling,
  tillering,
  booting,
  heading,
  grainFilling,
  maturity
}

/// Multiple linear-regression-style yield prediction.
///
/// This is a *thesis-grade baseline* — a small, explainable model that
/// combines well-known agro-weather drivers with the farmer's own
/// disease/pest observations. It is **not** a trained ML model; the
/// coefficients come from published literature on Thai rice agronomy
/// (Pathumthani Rice Research Center, 2018; IRRI, 2020) and can be
/// refined later with real yield data via a regression fit.
///
/// Output: predicted yield in tonnes/rai. Reference yields:
///   * Thai average (irrigated):         ~0.75 t/rai
///   * Good management + favourable wx:  ~1.00 t/rai
///   * Stress (disease/drought/flood):   ~0.50 t/rai
class YieldPredictionService {
  /// Provincial baseline yield (tonnes per rai). Based on the national
  /// rice statistics 2020–2023 average.
  static const double baselineTonnesPerRai = 0.72;

  /// Preferred cumulative GDD (base 10°C) from transplant to harvest
  /// for Thai short-grain rice. Yield peaks near this number.
  static const double optimalCumGdd = 2400;

  /// Predict yield (tonnes / rai) given:
  ///   - [cumulativeGdd] so far this season (base-10 °C)
  ///   - [daysSinceTransplant] elapsed days
  ///   - [diseaseIncidents] count of *flagged* disease detections
  ///   - [pestIncidents] count of pest detections with high confidence
  ///   - [rainfallMm] total rainfall in the season
  ///   - [farmSizeRai] (ไร่) — used to scale the return to total tonnes
  YieldPrediction predict({
    required double cumulativeGdd,
    required int daysSinceTransplant,
    required int diseaseIncidents,
    required int pestIncidents,
    required double rainfallMm,
    required double farmSizeRai,
  }) {
    double yieldPerRai = baselineTonnesPerRai;

    // GDD contribution — bell-curve around the optimum. Anything
    // > ±500 GDD off the optimum scales the baseline down.
    final gddDelta = (cumulativeGdd - optimalCumGdd).abs();
    final gddFactor = math.exp(-math.pow(gddDelta / 600.0, 2).toDouble());
    yieldPerRai *= 0.7 + 0.3 * gddFactor; // [0.7, 1.0]

    // Disease penalty — each flagged incident shaves ~4% yield,
    // capped at -40%. Based on observed loss range for rice blast
    // and bacterial leaf blight.
    final diseasePenalty = math.min(0.04 * diseaseIncidents, 0.40);
    yieldPerRai *= (1 - diseasePenalty);

    // Pest penalty — slightly smaller effect per incident.
    final pestPenalty = math.min(0.03 * pestIncidents, 0.30);
    yieldPerRai *= (1 - pestPenalty);

    // Rainfall — too little or too much both reduce yield. Thai rice
    // wants ~1,200–1,600 mm per season.
    double rainFactor;
    if (rainfallMm < 600) {
      rainFactor = 0.70; // drought
    } else if (rainfallMm < 1000) {
      rainFactor = 0.85;
    } else if (rainfallMm < 1800) {
      rainFactor = 1.00;
    } else if (rainfallMm < 2400) {
      rainFactor = 0.88; // too much rain — lodging risk
    } else {
      rainFactor = 0.72; // flooding
    }
    yieldPerRai *= rainFactor;

    // Clamp to sensible range.
    yieldPerRai = yieldPerRai.clamp(0.10, 1.30);

    // Growth-stage confidence — early season predictions are wobbly.
    final stage = _stageFor(daysSinceTransplant);
    final stageConfidence = switch (stage) {
      GrowthStage.seedling => 0.40,
      GrowthStage.tillering => 0.55,
      GrowthStage.booting => 0.70,
      GrowthStage.heading => 0.82,
      GrowthStage.grainFilling => 0.90,
      GrowthStage.maturity => 0.96,
    };

    return YieldPrediction(
      tonnesPerRai: yieldPerRai,
      totalTonnes: yieldPerRai * farmSizeRai,
      confidence: stageConfidence,
      stage: stage,
      factors: YieldFactors(
        gdd: gddFactor,
        disease: 1 - diseasePenalty,
        pest: 1 - pestPenalty,
        rainfall: rainFactor,
      ),
    );
  }

  /// Projection of predicted yield over the coming weeks, assuming the
  /// season continues at the current pace. Used to draw the chart.
  List<YieldPrediction> projection({
    required double cumulativeGdd,
    required int daysSinceTransplant,
    required int diseaseIncidents,
    required int pestIncidents,
    required double rainfallMm,
    required double farmSizeRai,
    int weeksAhead = 6,
    double weeklyGddGain = 170,
    double weeklyRainGain = 120,
  }) {
    final out = <YieldPrediction>[];
    for (var w = 0; w <= weeksAhead; w++) {
      out.add(
        predict(
          cumulativeGdd: cumulativeGdd + weeklyGddGain * w,
          daysSinceTransplant: daysSinceTransplant + 7 * w,
          diseaseIncidents: diseaseIncidents,
          pestIncidents: pestIncidents,
          rainfallMm: rainfallMm + weeklyRainGain * w,
          farmSizeRai: farmSizeRai,
        ),
      );
    }
    return out;
  }

  GrowthStage _stageFor(int days) {
    if (days < 25) return GrowthStage.seedling;
    if (days < 55) return GrowthStage.tillering;
    if (days < 75) return GrowthStage.booting;
    if (days < 95) return GrowthStage.heading;
    if (days < 115) return GrowthStage.grainFilling;
    return GrowthStage.maturity;
  }
}

class YieldPrediction {
  final double tonnesPerRai;
  final double totalTonnes;
  final double confidence; // 0..1
  final GrowthStage stage;
  final YieldFactors factors;

  const YieldPrediction({
    required this.tonnesPerRai,
    required this.totalTonnes,
    required this.confidence,
    required this.stage,
    required this.factors,
  });

  String get stageTh {
    switch (stage) {
      case GrowthStage.seedling:
        return 'ระยะกล้า';
      case GrowthStage.tillering:
        return 'ระยะแตกกอ';
      case GrowthStage.booting:
        return 'ระยะตั้งท้อง';
      case GrowthStage.heading:
        return 'ระยะออกรวง';
      case GrowthStage.grainFilling:
        return 'ระยะน้ำนม';
      case GrowthStage.maturity:
        return 'ระยะเก็บเกี่ยว';
    }
  }
}

class YieldFactors {
  final double gdd; // 0..1 — weather-heat fit
  final double disease; // 0..1 — disease-free fraction
  final double pest; // 0..1 — pest-free fraction
  final double rainfall; // 0..1 — rainfall fit
  const YieldFactors({
    required this.gdd,
    required this.disease,
    required this.pest,
    required this.rainfall,
  });
}
