import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/outbreak_alert.dart';
import '../../../models/weather_forecast.dart';
import '../../admin/providers/admin_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../weather/providers/weather_providers.dart';

/// Home dashboard (mockup screens 3 & 13) — greeting app bar, an active
/// outbreak banner, a weather summary, and the four primary feature
/// tiles, with a bottom navigation bar.
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
    final profile = ref.watch(profileControllerProvider);
    final alerts = ref.watch(activeAlertsProvider);
    final name = profile?.name ?? 'ชาวนา';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.spa, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'สวัสดี $name',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'การแจ้งเตือน',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/community'),
          ),
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
          ...alerts.maybeWhen(
            data: (list) => list
                .take(1)
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OutbreakBanner(alert: a),
                  ),
                )
                .toList(),
            orElse: () => const [],
          ),
          _WeatherCard(
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
            childAspectRatio: 1.25,
            children: [
              _FeatureTile(
                icon: Icons.coronavirus_outlined,
                title: 'ถามโรคข้าว',
                subtitle: 'ถ่ายรูปวินิจฉัย',
                background: const Color(0xFFEAF3DE),
                foreground: const Color(0xFF27500A),
                onTap: () => context.push('/disease-detection'),
              ),
              _FeatureTile(
                icon: Icons.bug_report_outlined,
                title: 'ถามศัตรูพืช',
                subtitle: 'ตรวจแมลง',
                background: const Color(0xFFFAEEDA),
                foreground: const Color(0xFF854F0B),
                onTap: () => context.push('/pest-identification'),
              ),
              _FeatureTile(
                icon: Icons.chat_bubble_outline,
                title: 'ถามพัสดี',
                subtitle: 'ผู้ช่วย AI',
                background: const Color(0xFFE1F5EE),
                foreground: AppColors.adminTeal,
                onTap: () => context.push('/chatbot'),
              ),
              _FeatureTile(
                icon: Icons.show_chart,
                title: 'ผลผลิต',
                subtitle: 'คาดการณ์',
                background: const Color(0xFFE6F1FB),
                foreground: AppColors.adminBlue,
                onTap: () => context.push('/yield'),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          switch (i) {
            case 1:
              context.push('/community');
            case 2:
              context.push('/weather');
            case 3:
              context.push('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'ชุมชน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            label: 'อากาศ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

/// Red outbreak banner (mockup screen 13) shown when an admin has
/// broadcast a warning for the farmer's area.
class _OutbreakBanner extends StatelessWidget {
  final OutbreakAlert alert;
  const _OutbreakBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เตือน${alert.conditionNameTh}ระบาด',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.message,
            style: const TextStyle(color: Color(0xFF791F1F), height: 1.4),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 13,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${alert.areaLabel} · ${_ago(alert.broadcastAt)}',
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes} นาทีที่แล้ว';
    if (d.inHours < 24) return '${d.inHours} ชม.ที่แล้ว';
    return DateFormat('d MMM', 'th').format(t);
  }
}

class _WeatherCard extends StatelessWidget {
  final AsyncValue<WeatherForecast?> asyncForecast;
  final VoidCallback onTap;
  const _WeatherCard({required this.asyncForecast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: asyncForecast.when(
          data: (f) {
            if (f == null || f.daily.isEmpty) {
              return const Row(
                children: [
                  Icon(Icons.location_off, color: AppColors.adminTeal),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('ยังไม่ได้เลือกตำแหน่ง แตะเพื่อเลือกจังหวัด'),
                  ),
                ],
              );
            }
            final today = f.daily.first;
            return Row(
              children: [
                const Icon(
                  Icons.wb_sunny,
                  color: AppColors.adminTeal,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${today.temperature.round()}°C · ${today.condition}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.adminTeal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.provinceTh ?? f.summary,
                        style: const TextStyle(color: AppColors.adminTeal),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.adminTeal),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 44,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Row(
            children: [
              Icon(Icons.cloud_off, color: AppColors.adminTeal),
              SizedBox(width: 12),
              Expanded(child: Text('โหลดพยากรณ์อากาศไม่ได้ แตะเพื่อลองใหม่')),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
