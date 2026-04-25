import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// 3-slide onboarding, shown on first launch only.
///
/// Completion sets `onboarding_complete = true` in SharedPreferences;
/// the dashboard's launch hook checks this flag and redirects new
/// users here.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.spa,
      title: 'ยินดีต้อนรับสู่ RiceSmart',
      body: 'ผู้ช่วยชาวนาไทยด้วย AI\n'
          'ลดต้นทุน เพิ่มผลผลิต ดูแลข้าวได้ตลอดฤดู',
      color: AppColors.primary,
    ),
    _OnboardingSlide(
      icon: Icons.camera_alt_outlined,
      title: 'วินิจฉัยโรคและศัตรูพืชจากภาพ',
      body: 'ถ่ายรูปใบข้าวหรือแมลง\n'
          'AI บนเครื่องวิเคราะห์ให้ทันทีแม้ไม่มีเน็ต',
      color: AppColors.secondary,
    ),
    _OnboardingSlide(
      icon: Icons.forum_outlined,
      title: 'พูดคุยกับพัสดี',
      body: 'พัสดี (พ.ผู้ช่วยชาวนา) พร้อมตอบทุกคำถาม\n'
          'รู้ทั้งเทคนิคโบราณและเทคโนโลยีสมัยใหม่',
      color: AppColors.info,
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _OnboardingView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        i == _page ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _complete,
                    child: const Text('ข้าม'),
                  ),
                  const Spacer(),
                  if (_page < _slides.length - 1)
                    ElevatedButton(
                      onPressed: () => _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('ถัดไป'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _complete,
                      icon: const Icon(Icons.check),
                      label: const Text('เริ่มใช้งาน'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _OnboardingView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _OnboardingView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: slide.color.withValues(alpha: 0.12),
            child: Icon(slide.icon, size: 72, color: slide.color),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }
}
