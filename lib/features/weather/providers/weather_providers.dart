import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/env.dart';
import '../../../models/weather_forecast.dart';
import '../services/weather_service.dart';
import 'location_providers.dart';

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

/// Current location query for weather forecast.
///
/// Initialization chain (in order of preference):
/// 1. User's saved location (SharedPreferences)
/// 2. Device GPS location (with automatic province mapping)
/// 3. Null (trigger manual picker in UI)
///
/// Use [weatherQueryProvider] to get the finalized location.
final weatherLocationProvider =
    FutureProvider.autoDispose<WeatherQuery?>((ref) async {
  // Try saved location first
  final saved = await ref.watch(savedWeatherLocationProvider.future);
  if (saved != null) {
    return saved;
  }

  // Fall back to GPS
  return ref.watch(currentLocationProvider.future);
});

/// Finalized weather query with fallback handling.
///
/// Watches [weatherLocationProvider] and returns a usable [WeatherQuery].
/// Auto-populates from GPS detection if available, otherwise returns null (UI will show picker).
/// This is stateful so users can manually override via the picker.
final weatherQueryProvider = StateProvider<WeatherQuery?>((ref) {
  // Try to initialize from the auto-detected location
  final locationAsync = ref.watch(weatherLocationProvider);
  return locationAsync.whenData((query) => query).value;
});

/// Live 7-day forecast for [weatherQueryProvider].
final weatherForecastProvider = FutureProvider<WeatherForecast?>((ref) async {
  final q = ref.watch(weatherQueryProvider);
  if (q == null) {
    return null; // No location selected yet
  }

  return ref.watch(weatherServiceProvider).fetchForecast(
        lat: q.lat,
        lon: q.lon,
        tmdApiKey: Env.tmdApiKey,
        provinceTh: q.provinceTh,
      );
});
