import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chatbot/screens/chatbot_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/disease_detection/screens/disease_detection_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/pest_identification/screens/pest_identification_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/weather/screens/weather_screen.dart';

/// App router — the dashboard at `/` is the home screen and other
/// features navigate via `context.push(...)`. A seed prompt can be
/// handed to the chatbot via `extra` so disease/pest results flow into
/// a Pasadee follow-up automatically.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/disease-detection',
        name: 'diseaseDetection',
        builder: (context, state) => const DiseaseDetectionScreen(),
      ),
      GoRoute(
        path: '/pest-identification',
        name: 'pestIdentification',
        builder: (context, state) => const PestIdentificationScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        name: 'chatbot',
        builder: (context, state) {
          final seed = state.extra is String ? state.extra as String : null;
          return ChatbotScreen(initialPrompt: seed);
        },
      ),
      GoRoute(
        path: '/weather',
        name: 'weather',
        builder: (context, state) => const WeatherScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
