import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/community_report.dart';
import '../../community/providers/community_providers.dart';
import '../providers/admin_providers.dart';

/// Outbreak confirmation + broadcast (mockup screen 12).
///
/// The admin reviews a hot [OutbreakCluster] and either closes the case
/// or broadcasts a warning, which becomes the red banner farmers see on
/// their dashboard (screen 13).
class OutbreakDetailScreen extends ConsumerWidget {
  final OutbreakCluster? cluster;
  const OutbreakDetailScreen({super.key, this.cluster});

  static const _radiusKm = 5.0;

  String _message(OutbreakCluster c) =>
      'พบการระบาดของ${c.conditionNameTh}ใกล้พื้นที่ของคุณ '
      '(ในรัศมี ${_radiusKm.toStringAsFixed(0)} กม.) '
      'ตรวจแปลงนาและงดให้น้ำขัง';

  Future<void> _broadcast(
    BuildContext context,
    WidgetRef ref,
    OutbreakCluster c,
  ) async {
    final area = c.provinceTh ?? 'พื้นที่เฝ้าระวัง';
    await ref.read(alertServiceProvider).broadcast(
          conditionId: c.conditionId,
          conditionNameTh: c.conditionNameTh,
          areaLabel: area,
          provinceTh: c.provinceTh,
          radiusKm: _radiusKm,
          pointCount: c.reportCount,
          message: _message(c),
        );
    refreshAdmin(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('กระจายเตือน${c.conditionNameTh}ไปยัง$area แล้ว')),
    );
    context.go('/admin/map');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the passed cluster, or fall back to the first hot cluster (e.g.
    // after a hot-reload that drops the `extra` payload).
    final fallback = ref.watch(outbreakClustersProvider).valueOrNull;
    final c =
        cluster ?? (fallback?.isNotEmpty == true ? fallback!.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการระบาด'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: c == null
          ? const Center(child: Text('ไม่พบข้อมูลการระบาด'))
          : _Body(
              cluster: c,
              message: _message(c),
              onClose: () => context.go('/admin/map'),
              onBroadcast: () => _broadcast(context, ref, c),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  final OutbreakCluster cluster;
  final String message;
  final VoidCallback onClose;
  final VoidCallback onBroadcast;

  const _Body({
    required this.cluster,
    required this.message,
    required this.onClose,
    required this.onBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    final affected = cluster.reportCount * 6; // rough reach estimate
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cluster.conditionNameTh,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const Text('ตรวจพบเข้าเกณฑ์การระบาด'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                  label: 'จุดที่พบ',
                  value: '${cluster.reportCount}',
                  color: AppColors.error,),
              const SizedBox(width: 8),
              const _Stat(label: 'รัศมี', value: '5 กม.'),
              const SizedBox(width: 8),
              _Stat(label: 'ช่วงพบ', value: '${cluster.windowDays} วัน'),
            ],
          ),
          const SizedBox(height: 16),
          _Kv(label: 'พื้นที่', value: cluster.provinceTh ?? '—'),
          _Kv(label: 'ผู้ใช้กระทบ', value: '~ $affected ราย'),
          const _Kv(label: 'ความมั่นใจเฉลี่ย', value: '89%', last: true),
          const SizedBox(height: 16),
          const Text(
            'ตัวอย่างที่จะส่งให้ผู้ใช้',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_active,
                    color: Colors.white, size: 22,),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เตือน${cluster.conditionNameTh}ระบาด',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  label: const Text('ปิดเคส'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onBroadcast,
                  icon: const Icon(Icons.send),
                  label: const Text('กระจายเตือน'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _Kv({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
