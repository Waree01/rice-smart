import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../providers/weather_providers.dart';

/// Repository for persisting and loading user's selected weather location.
///
/// Uses FlutterSecureStorage to securely store:
/// - `weather_location_province_th` — Thai province name
/// - `weather_location_lat` — latitude as string
/// - `weather_location_lon` — longitude as string
///
/// GPS coordinates are encrypted at rest to protect farmer privacy.
/// Provides offline-first access to the user's last chosen location.
class LocationRepository {
  static const _keyProvinceTh = 'weather_location_province_th';
  static const _keyLatitude = 'weather_location_lat';
  static const _keyLongitude = 'weather_location_lon';

  final FlutterSecureStorage _storage;
  final Logger _logger;

  LocationRepository({
    required FlutterSecureStorage storage,
    Logger? logger,
  })  : _storage = storage,
        _logger = logger ?? Logger();

  /// Save a location to encrypted persistent storage.
  ///
  /// Stores the province name, latitude, and longitude from [query].
  /// GPS coordinates are encrypted at rest for privacy.
  /// All three fields are required; returns false if any is invalid.
  Future<bool> saveLocation(WeatherQuery query) async {
    try {
      _logger.i('Saving location: ${query.provinceTh}');

      await Future.wait([
        _storage.write(key: _keyProvinceTh, value: query.provinceTh ?? ''),
        _storage.write(key: _keyLatitude, value: query.lat.toString()),
        _storage.write(key: _keyLongitude, value: query.lon.toString()),
      ]);

      _logger.i('Location saved successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to save location', error: e);
      return false;
    }
  }

  /// Load the user's saved location from encrypted persistent storage.
  ///
  /// Returns a [WeatherQuery] if all three keys exist and are valid.
  /// Validates that coordinates fall within valid GPS bounds.
  /// Returns null if no location has been saved, values are missing, or out of bounds.
  Future<WeatherQuery?> loadLocation() async {
    try {
      final provinceTh = await _storage.read(key: _keyProvinceTh);
      final latStr = await _storage.read(key: _keyLatitude);
      final lonStr = await _storage.read(key: _keyLongitude);

      if (provinceTh == null || latStr == null || lonStr == null) {
        _logger.i('No saved location found');
        return null;
      }

      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);

      if (lat == null || lon == null) {
        _logger.w('Saved location has invalid coordinates');
        return null;
      }

      // Validate GPS bounds: latitude [-90, 90], longitude [-180, 180]
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
        _logger.w('Saved location has out-of-bounds coordinates');
        return null;
      }

      final query = WeatherQuery(
        lat: lat,
        lon: lon,
        provinceTh: provinceTh.isNotEmpty ? provinceTh : null,
      );

      _logger.i('Loaded location: $provinceTh');
      return query;
    } catch (e) {
      _logger.e('Error loading location', error: e);
      return null;
    }
  }

  /// Clear the saved location from encrypted persistent storage.
  Future<bool> clearLocation() async {
    try {
      _logger.i('Clearing saved location');

      await Future.wait([
        _storage.delete(key: _keyProvinceTh),
        _storage.delete(key: _keyLatitude),
        _storage.delete(key: _keyLongitude),
      ]);

      _logger.i('Location cleared');
      return true;
    } catch (e) {
      _logger.e('Failed to clear location', error: e);
      return false;
    }
  }
}
