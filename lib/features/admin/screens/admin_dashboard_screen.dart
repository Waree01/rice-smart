import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../community/providers/community_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_bottom_nav.dart';

/// Admin dashboard (mockup screen 7) — quality-control + data-labeling
/// home. Shows headline stats and a management menu. Demo data is seeded
/// once on first open via [adminSeedProvider].
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick the one-shot demo seeding; the FutureProviders below refresh
    // automatically once it completes because they're invalidated there.
    final seed = ref.watch(adminSeedProvider);
    final stats = ref.watch(reviewStatsProvider);
    final users = ref.watch(usersProvider);
    final clusters = ref.watch(outbreakClustersProvider);

    final pending = stats.valueOrNull?.pending ?? 0;
    final labeledToday = stats.valueOrNull?.labeledToday ?? 0;
    final accuracy = stats.valueOrNull?.modelAccuracy;
    final userCount = users.valueOrNull?.length ?? 0;
    final outbreakCount = clusters.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แอดมิน'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        leading: const Icon(Icons.shield_outlined),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAdmin(ref),
          ),
        ],
      ),
      body: seed.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _MetricCard(
                      label: 'รอตรวจสอบ',
                      value: '$pending',
                      color: AppColors.adminAmber,
                    ),
                    _MetricCard(
                      label: 'ติดป้ายวันนี้',
                      value: '$labeledToday',
                      color: AppColors.primary,
                    ),
                    _MetricCard(
                      label: 'ผู้ใช้ทั้งหมด',
                      value: '$userCount',
                      color: Colors.black87,
                    ),
                    _MetricCard(
                      label: 'ความแม่นโมเดล',
                      value: accuracy == null
                          ? '—'
                          : '${(accuracy * 100).round()}%',
                      color: AppColors.adminTeal,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'เมนูจัดการ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                _MenuRow(
                  icon: Icons.inbox_outlined,
                  iconColor: AppColors.adminAmber,
                  title: 'คิวรอตรวจสอบ',
                  subtitle: 'ภาพที่ AI ไม่มั่นใจ',
                  badge: pending > 0 ? '$pending' : null,
                  badgeColor: AppColors.adminAmber,
                  onTap: () => context.go('/admin/review'),
                ),
                _MenuRow(
                  icon: Icons.label_outline,
                  iconColor: AppColors.primary,
                  title: 'ติดป้ายข้อมูล',
                  subtitle: 'Active learning loop',
                  onTap: () => context.go('/admin/labeling'),
                ),
                _MenuRow(
                  icon: Icons.map_outlined,
                  iconColor: AppColors.error,
                  title: 'แผนที่เฝ้าระวัง',
                  subtitle: 'จุดที่ AI เจอ + วงรัศมี',
                  badge: outbreakCount > 0 ? '$outbreakCount ระบาด' : null,
                  badgeColor: AppColors.error,
                  onTap: () => context.go('/admin/map'),
                ),
                _MenuRow(
                  icon: Icons.people_outline,
                  iconColor: AppColors.adminBlue,
                  title: 'จัดการผู้ใช้',
                  subtitle: 'สิทธิ์ + บทบาท',
                  onTap: () => context.go('/admin/users'),
                ),
              ],
            ),
      bottomNavigationBar: const AdminBottomNav(current: 0),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: badge != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: badgeColor ?? AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
