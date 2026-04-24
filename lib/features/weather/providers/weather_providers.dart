import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/env.dart';
import '../../../models/weather_forecast.dart';
import '../services/weather_service.dart';

final weatherServiceProvider =
    Provider<WeatherService>((ref) => WeatherService());

/// Query parameters for the current forecast fetch.
class WeatherQuery {
  final double lat;
  final double lon;
  final String? provinceTh;
  const WeatherQuery({
    required this.lat,
    required this.lon,
    this.provinceTh,
  });
}

/// Default location — Sukhothai (rice-growing heartland). The real
/// onboarding flow persists a user-chosen province.
final weatherQueryProvider = StateProvider<WeatherQuery>(
  (ref) => const WeatherQuery(
    lat: 17.006,
    lon: 99.823,
    provinceTh: 'สุโขทัย',
  ),
);

/// Live 7-day forecast for [weatherQueryProvider].
final weatherForecastProvider = FutureProvider<WeatherForecast>((ref) async {
  final q = ref.watch(weatherQueryProvider);
  return ref.watch(weatherServiceProvider).fetchForecast(
        lat: q.lat,
        lon: q.lon,
        tmdApiKey: Env.tmdApiKey,
        provinceTh: q.provinceTh,
      );
});
