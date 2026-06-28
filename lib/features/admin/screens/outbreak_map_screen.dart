import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/community_report.dart';
import '../../community/providers/community_providers.dart';
import '../widgets/admin_bottom_nav.dart';

/// Outbreak surveillance map (mockup screen 11).
///
/// Renders hot [OutbreakCluster]s as a stylized pin map with a 5 km
/// watch radius, plus an alert banner per cluster that opens the
/// broadcast confirmation screen.
class OutbreakMapScreen extends ConsumerWidget {
  const OutbreakMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clusters = ref.watch(outbreakClustersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่เฝ้าระวัง'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: clusters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('โหลดแผนที่ไม่สำเร็จ: $e')),
        data: (list) {
          final hot = list.where((c) => c.reportCount >= 3).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MapView(pointCount: hot.isEmpty ? 0 : hot.first.reportCount),
              const SizedBox(height: 12),
              const _Legend(),
              const SizedBox(height: 16),
              if (hot.isEmpty)
                Card(
                  color: AppColors.success.withValues(alpha: 0.08),
                  child: const ListTile(
                    leading:
                        Icon(Icons.verified_outlined, color: AppColors.success),
                    title: Text('ยังไม่พบการระบาดเกินเกณฑ์'),
                    subtitle: Text(
                        'ระบบจะรวมจุดที่ AI ยืนยันโรคเดียวกันโดยอัตโนมัติ',),
                  ),
                )
              else
                for (final c in hot)
                  _OutbreakAlertCard(
                    cluster: c,
                    onTap: () => context.push('/admin/outbreak', extra: c),
                  ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNav(current: 3),
    );
  }
}

class _MapView extends StatelessWidget {
  final int pointCount;
  const _MapView({required this.pointCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: CustomPaint(
          painter: _MapPainter(pointCount: pointCount),
          child: pointCount > 0
              ? Align(
                  alignment: const Alignment(-0.35, -0.78),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pointCount จุด',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final int pointCount;
  _MapPainter({required this.pointCount});

  @override
  void paint(Canvas canvas, Size size) {
    // Paddy-field backdrop — alternating green bands.
    final band1 = Paint()..color = const Color(0xFFEAF3DE);
    final band2 = Paint()..color = const Color(0xFFE1E9D4);
    const bandH = 22.0;
    for (var y = 0.0; y < size.height; y += bandH * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, bandH), band1);
      canvas.drawRect(
        Rect.fromLTWH(0, y + bandH, size.width, bandH),
        band2,
      );
    }

    // Roads.
    final road = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.54, size.width, 6),
      road,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.40, 0, 6, size.height),
      road,
    );

    if (pointCount <= 0) return;

    // 5 km watch radius around the cluster centroid.
    final center = Offset(size.width * 0.34, size.height * 0.42);
    final radius = size.width * 0.30;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.error.withValues(alpha: 0.12),
    );
    _drawDashedCircle(canvas, center, radius);

    // Red pins clustered inside the radius (deterministic scatter).
    final rng = math.Random(7);
    final pins = math.min(pointCount, 14);
    for (var i = 0; i < pins; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final r = radius * (0.2 + rng.nextDouble() * 0.7);
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      _drawPin(canvas, p, AppColors.error);
    }
    // A couple of amber watch pins outside the cluster.
    _drawPin(
      canvas,
      Offset(size.width * 0.78, size.height * 0.72),
      AppColors.adminAmber,
    );
    _drawPin(
      canvas,
      Offset(size.width * 0.86, size.height * 0.82),
      AppColors.adminAmber,
    );
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFA32D2D);
    const dashes = 40;
    for (var i = 0; i < dashes; i++) {
      if (i.isOdd) continue;
      final a0 = (i / dashes) * math.pi * 2;
      final a1 = ((i + 1) / dashes) * math.pi * 2;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, a0, a1 - a0, false, paint);
    }
  }

  void _drawPin(Canvas canvas, Offset p, Color color) {
    canvas.drawCircle(p, 6, Paint()..color = color);
    canvas.drawCircle(
      p,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.pointCount != pointCount;
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Dot(color: AppColors.error, label: 'กำลังระบาด'),
        SizedBox(width: 16),
        _Dot(color: AppColors.adminAmber, label: 'เฝ้าระวัง'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
      ],
    );
  }
}

class _OutbreakAlertCard extends StatelessWidget {
  final OutbreakCluster cluster;
  final VoidCallback onTap;
  const _OutbreakAlertCard({required this.cluster, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: AppColors.error),
        title: Text(
          '${cluster.conditionNameTh} · ${cluster.provinceTh ?? 'พื้นที่เฝ้าระวัง'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${cluster.reportCount} จุด ใน 5 กม. · เกินเกณฑ์การระบาด',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
