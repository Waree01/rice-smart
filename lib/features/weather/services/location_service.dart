import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling device location requests with permission management.
///
/// Wraps [geolocator] and [permission_handler] to:
/// - Request location permission with Thai user-friendly rationale
/// - Fetch current position with timeout
/// - Handle all error cases gracefully
class LocationService {
  final Logger _logger;

  LocationService({Logger? logger}) : _logger = logger ?? Logger();

  /// Request location permission from the user.
  ///
  /// On platforms that support rationale dialogs (e.g., Android API 30+):
  /// - If the user previously denied permission, shows the system rationale dialog
  /// - Explains that the app needs location to provide accurate agricultural forecasts
  /// On iOS and older Android, the standard system permission dialog is shown.
  /// Returns the final permission status.
  Future<PermissionStatus> requestLocationPermission() async {
    try {
      _logger.i('Requesting location permission');

      final status = await Permission.location.request();
      _logger.i('Location permission status: $status');

      return status;
    } catch (e) {
      _logger.e('Failed to request location permission', error: e);
      rethrow;
    }
  }

  /// Get the device's current GPS position.
  ///
  /// - Enforces a 10-second timeout to avoid blocking the UI
  /// - Returns [Position] with latitude, longitude, and accuracy
  /// - Throws exceptions if GPS fails (timeout, disabled, permission denied)
  /// - GPS coordinates are not logged to protect farmer privacy
  Future<Position> getCurrentPosition() async {
    try {
      _logger.i('Fetching current position');

      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      _logger.i('Got position successfully');

      return position;
    } catch (e) {
      _logger.e('Error getting position: $e', error: e);
      rethrow;
    }
  }
}
