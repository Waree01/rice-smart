// Widget smoke tests.
//
// The dashboard reads SharedPreferences in `initState` and the weather
// provider fires an HTTP request. We pre-seed SharedPreferences so the
// dashboard doesn't redirect to onboarding, and we only pump a couple of
// frames instead of `pumpAndSettle()` to avoid waiting on the network
// future. The weather provider's error path falls back to synthetic
// data, so a failed HTTP call does not crash the tree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rice_smart/app.dart';
import 'package:rice_smart/core/constants/app_constants.dart';
import 'package:rice_smart/features/onboarding/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppConstants.onboardingKey: true,
    });
  });

  testWidgets('Dashboard renders Pasadee welcome and four feature cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RiceSmartApp()),
    );
    // A few frames are enough — avoid pumpAndSettle so pending HTTP
    // futures don't block the test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('พัสดี'), findsWidgets);
    expect(find.text('วินิจฉัยโรคข้าว'), findsOneWidget);
    expect(find.text('ระบุศัตรูพืช'), findsOneWidget);
    expect(find.text('คุยกับพัสดี'), findsOneWidget);
    expect(find.text('พยากรณ์อากาศ'), findsOneWidget);
  });

  testWidgets('Onboarding welcome slide renders and exposes a next button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('ถัดไป'), findsOneWidget);
    expect(find.textContaining('ยินดีต้อนรับ'), findsOneWidget);
  });
}
