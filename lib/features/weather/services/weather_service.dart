import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_constants.dart';

/// Weather service integrating TMD API and NASA POWER fallback
/// Provides agro-weather data for Pasadee's farming suggestions
class WeatherService {
  final Dio _dio;
  final Logger _logger = Logger();

  WeatherService({Dio? dio}) : _dio = dio ?? Dio();

  /// Get weather forecast from Thai Meteorological Department
  Future<Map<String, dynamic>> getTmdForecast({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.tmdBaseUrl}/forecast/location/daily/at',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'fields': 'tc,rh,rain,ws10m,cond',
          'duration': 7,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        }),
      );
      return response.data;
    } catch (e) {
      _logger.w('TMD API failed, falling back to NASA POWER', error: e);
      return getNasaPowerData(lat: lat, lon: lon);
    }
  }

  /// Fallback: NASA POWER satellite weather data
  Future<Map<String, dynamic>> getNasaPowerData({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.nasaPowerUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'community': 'AG',
          'parameters': 'T2M,RH2M,PRECTOTCORR,WS2M',
          'format': 'JSON',
          'start': _formatDate(DateTime.now()),
          'end': _formatDate(DateTime.now().add(const Duration(days: 7))),
        },
      );
      return response.data;
    } catch (e) {
      _logger.e('NASA POWER API also failed', error: e);
      rethrow;
    }
  }

  /// Calculate disease risk score from weather data
  /// High humidity + warm temp = high disease risk
  double calculateDiseaseRiskScore({
    required double temperature,
    required double humidity,
    required double rainfall,
  }) {
    double risk = 0.0;

    // Blast disease thrives at 25-28°C with high humidity
    if (temperature >= 25 && temperature <= 28) risk += 0.3;
    if (humidity > 85) risk += 0.4;
    if (rainfall > 10) risk += 0.3;

    return risk.clamp(0.0, 1.0);
  }

  /// Calculate Growing Degree Days (GDD)
  double calculateGDD({
    required double maxTemp,
    required double minTemp,
    double baseTemp = 10.0,
  }) {
    final avgTemp = (maxTemp + minTemp) / 2;
    return (avgTemp - baseTemp).clamp(0.0, double.infinity);
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
