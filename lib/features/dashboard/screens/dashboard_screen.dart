import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/weather_forecast.dart';
import '../../weather/providers/weather_providers.dart';

/// Home dashboard — four feature tiles + a weather summary card and a
/// settings action. On first launch this also kicks the user into the
/// onboarding flow.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding());
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(AppConstants.onboardingKey) ?? false;
    if (!mounted) return;
    if (!done) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final forecast = ref.watch(weatherForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('${AppConstants.appName} · ${AppConstants.chatbotNameThai}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ตั้งค่า',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.primaryLight.withOpacity(0.15),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'สวัสดีครับ! ผมพัสดี',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ผู้ช่วยชาวนาอัจฉริยะ พร้อมดูแลนาข้าวของคุณทุกฤดู',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _WeatherSummaryCard(
            asyncForecast: forecast,
            onTap: () => context.push('/weather'),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _FeatureCard(
                icon: Icons.local_florist,
                title: 'วินิจฉัยโรคข้าว',
                subtitle: 'ถ่ายรูปใบข้าว AI วิเคราะห์',
                color: AppColors.error,
                onTap: () => context.push('/disease-detection'),
              ),
              _FeatureCard(
                icon: Icons.bug_report,
                title: 'ระบุศัตรูพืช',
                subtitle: 'ถ่ายรูปแมลง AI ระบุชนิด',
                color: AppColors.warning,
                onTap: () => context.push('/pest-identification'),
              ),
              _FeatureCard(
                icon: Icons.chat,
                title: 'คุยกับพัสดี',
                subtitle: 'ถามเรื่องปลูกข้าวได้เลย',
                color: AppColors.primary,
                onTap: () => context.push('/chatbot'),
              ),
              _FeatureCard(
                icon: Icons.cloud,
                title: 'พยากรณ์อากาศ',
                subtitle: 'สภาพอากาศและคำแนะนำ',
                color: AppColors.info,
                onTap: () => context.push('/weather'),
              ),
              _FeatureCard(
                icon: Icons.analytics_outlined,
                title: 'ประมาณการผลผลิต',
                subtitle: 'คำนวณจาก GDD โรค ศัตรูพืช',
                color: AppColors.secondary,
                onTap: () => context.push('/yield'),
              ),
              _FeatureCard(
                icon: Icons.groups,
                title: 'ชุมชน',
                subtitle: 'เฝ้าระวังการระบาดในพื้นที่',
                color: AppColors.primary,
                onTap: () => context.push('/community'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  final AsyncValue<WeatherForecast?> asyncForecast;
  final VoidCallback onTap;
  const _WeatherSummaryCard({
    required this.asyncForecast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: asyncForecast.when(
            data: (f) => f == null
                ? const Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.grey, size: 36),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              'ยังไม่ได้เลือกตำแหน่ง แตะเพื่อเลือกจังหวัด')),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: AppColors.info, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.provinceTh ?? 'สภาพอากาศ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(f.summary,
                                style: TextStyle(color: Colors.grey[800])),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.grey, size: 36),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'ไม่สามารถโหลดพยากรณ์อากาศได้ แตะเพื่อลองใหม่')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
