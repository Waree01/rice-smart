import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/disease_detection/screens/disease_detection_screen.dart';
import '../features/pest_identification/screens/pest_identification_screen.dart';
import '../features/chatbot/screens/chatbot_screen.dart';

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
        builder: (context, state) => const ChatbotScreen(),
      ),
    ],
  );
});
