import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/location_repository.dart';
import '../data/thai_provinces.dart';
import '../services/location_service.dart';
import 'weather_providers.dart';

/// Provides a singleton [LocationService] for device location access.
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Provides a singleton [LocationRepository] for secure location persistence.
final locationRepositoryProvider =
    FutureProvider<LocationRepository>((ref) async {
  const storage = FlutterSecureStorage();
  return LocationRepository(storage: storage);
});

/// Load user's previously saved weather location from secure storage.
///
/// Returns null if no location has been saved or coordinates are invalid.
/// Does not trigger location permission requests.
final savedWeatherLocationProvider = FutureProvider<WeatherQuery?>((ref) async {
  final repo = await ref.watch(locationRepositoryProvider.future);
  return repo.loadLocation();
});

/// Fetch current device location and map to nearest Thai province.
///
/// **Flow:**
/// 1. Request location permission (if not already granted)
/// 2. Fetch GPS position with 10-second timeout
/// 3. Validate coordinates are within valid bounds (lat: [-90, 90], lon: [-180, 180])
/// 4. Map GPS coords to nearest Thai province using Euclidean distance
/// 5. Return [WeatherQuery] with province + coordinates
///
/// **On failure:**
/// - Permission denied → returns null (user can retry with picker)
/// - GPS timeout/disabled → returns null
/// - Coordinates out of bounds → returns null
/// - Any other error → logs and returns null
///
/// This is auto-dispose to avoid holding onto location requests after UI unmounts.
final currentLocationProvider =
    FutureProvider.autoDispose<WeatherQuery?>((ref) async {
  final service = ref.watch(locationServiceProvider);

  try {
    // Check permission first
    final permStatus = await service.requestLocationPermission();
    if (!permStatus.isGranted) {
      return null; // User denied — allow fallback to picker
    }

    // Fetch position with 10-second timeout
    final position = await service.getCurrentPosition();

    // Validate GPS bounds: latitude [-90, 90], longitude [-180, 180]
    if (position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      return null; // Out of bounds — allow fallback to picker
    }

    // Map to nearest province
    final province = nearestProvince(position.latitude, position.longitude);

    return WeatherQuery(
      lat: position.latitude,
      lon: position.longitude,
      provinceTh: province.nameTh,
    );
  } catch (e) {
    // Any error (timeout, disabled, permission denied) — allow fallback
    return null;
  }
});
