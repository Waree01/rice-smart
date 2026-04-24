import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/features/weather/services/weather_service.dart';

void main() {
  final service = WeatherService();

  group('WeatherService.calculateDiseaseRiskScore', () {
    test('peak risk at warm + humid + wet conditions', () {
      final risk = service.calculateDiseaseRiskScore(
        temperature: 26,
        humidity: 90,
        rainfall: 15,
      );
      expect(risk, closeTo(1.0, 1e-9));
    });

    test('low risk on cool, dry day', () {
      final risk = service.calculateDiseaseRiskScore(
        temperature: 20,
        humidity: 60,
        rainfall: 0,
      );
      expect(risk, 0.0);
    });

    test('partial contributions are additive', () {
      // temperature in range (+0.3), humidity in range (+0.4), but dry.
      final risk = service.calculateDiseaseRiskScore(
        temperature: 27,
        humidity: 88,
        rainfall: 0,
      );
      expect(risk, closeTo(0.7, 1e-9));
    });

    test('result is always clamped to [0, 1]', () {
      final r = service.calculateDiseaseRiskScore(
        temperature: 26,
        humidity: 95,
        rainfall: 40,
      );
      expect(r, lessThanOrEqualTo(1.0));
      expect(r, greaterThanOrEqualTo(0.0));
    });
  });

  group('WeatherService.calculateGDD', () {
    test('classic example with default base', () {
      final gdd = service.calculateGDD(maxTemp: 35, minTemp: 25);
      expect(gdd, 20.0); // (35+25)/2 - 10
    });

    test('never negative when average below base', () {
      final gdd = service.calculateGDD(maxTemp: 10, minTemp: 5);
      expect(gdd, 0.0);
    });

    test('respects custom base', () {
      final gdd =
          service.calculateGDD(maxTemp: 30, minTemp: 20, baseTemp: 15);
      expect(gdd, 10.0);
    });
  });
}
