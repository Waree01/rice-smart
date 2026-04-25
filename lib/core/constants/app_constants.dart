/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'RiceSmart';
  static const String appNameThai = 'ไรซ์สมาร์ท';
  static const String chatbotName = 'Pasadee';
  static const String chatbotNameThai = 'พัสดี';

  // AI Model Files (TFLite)
  static const String diseaseModelPath =
      'assets/models/rice_disease_model.tflite';
  static const String pestModelPath =
      'assets/models/pest_detection_model.tflite';
  static const String diseaseLabelsPath = 'assets/models/disease_labels.txt';
  static const String pestLabelsPath = 'assets/models/pest_labels.txt';

  // Image Processing
  static const int imageInputSize = 224; // EfficientNet-B0 input
  static const double confidenceThreshold = 0.75;

  // API Endpoints
  static const String tmdBaseUrl = 'https://data.tmd.go.th/nwpapi/v1';
  static const String nasaPowerUrl =
      'https://power.larc.nasa.gov/api/temporal/daily/point';

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String onboardingKey = 'onboarding_complete';

  // Supported LLM Providers
  static const List<String> llmProviders = [
    'claude',
    'gpt',
    'gemini',
    'typhoon',
  ];
}
