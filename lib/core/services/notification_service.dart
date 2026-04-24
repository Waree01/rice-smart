import 'package:logger/logger.dart';

/// Push notification service — thin wrapper over Firebase Cloud Messaging.
///
/// This is a stub until Firebase is provisioned (google-services.json
/// for Android, GoogleService-Info.plist for iOS). Methods are all safe
/// to call before initialization — they just log a warning and return.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _logger = Logger();
  bool _initialized = false;

  Future<void> initialize() async {
    // Real implementation (uncomment after Firebase is wired):
    //
    //   final messaging = FirebaseMessaging.instance;
    //   await messaging.requestPermission();
    //   final token = await messaging.getToken();
    //   FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    //   FirebaseMessaging.onBackgroundMessage(_bgHandler);
    _initialized = true;
    _logger.i('NotificationService stub initialized');
  }

  Future<void> subscribeToWeatherAlerts(String province) async {
    if (!_initialized) {
      _logger.w('NotificationService not initialized — skipping subscribe');
      return;
    }
    // await FirebaseMessaging.instance.subscribeToTopic('weather_$province');
  }

  Future<void> subscribeToDiseaseAlerts() async {
    if (!_initialized) {
      _logger.w('NotificationService not initialized — skipping subscribe');
      return;
    }
    // await FirebaseMessaging.instance.subscribeToTopic('disease_alerts');
  }
}
