import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/community_report.dart';
import '../providers/community_providers.dart';

/// Community surveillance dashboard — shows recent reports and any
/// detected outbreak clusters in the neighbourhood.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(recentReportsProvider);
    final outbreaks = ref.watch(outbreakClustersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานในชุมชน'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(recentReportsProvider);
              ref.invalidate(outbreakClustersProvider);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OutbreakSection(async: outbreaks),
          const SizedBox(height: 16),
          Text('รายงานล่าสุด',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          reports.when(
            data: (list) => list.isEmpty
                ? const _Empty()
                : Column(
                    children: [
                      for (final r in list.take(30))
                        _ReportTile(report: r),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('โหลดรายงานไม่สำเร็จ: $e'),
          ),
          const SizedBox(height: 16),
          Text(
            'ข้อมูลถูกเก็บแบบ geohash ระดับ 5 (≈ 4.9 กม.) เพื่อรักษาความเป็นส่วนตัวของเจ้าของแปลง',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _OutbreakSection extends StatelessWidget {
  final AsyncValue<List<OutbreakCluster>> async;
  const _OutbreakSection({required this.async});

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (clusters) {
        if (clusters.isEmpty) {
          return Card(
            color: AppColors.success.withOpacity(0.08),
            child: const ListTile(
              leading: Icon(Icons.verified_outlined,
                  color: AppColors.success),
              title: Text('ยังไม่พบการระบาดในชุมชนของคุณ'),
              subtitle: Text(
                  'ระบบจะแจ้งเตือนเมื่อมีรายงานกระจุกตัวในพื้นที่เดียวกัน'),
            ),
          );
        }
        return Column(
          children: [
            for (final c in clusters) _OutbreakTile(cluster: c),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OutbreakTile extends StatelessWidget {
  final OutbreakCluster cluster;
  const _OutbreakTile({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.diseaseCritical.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber, color: AppColors.diseaseCritical),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เฝ้าระวัง: ${cluster.conditionNameTh}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'พบ ${cluster.reportCount} รายงานในเขต ${cluster.provinceTh ?? cluster.geohashPrefix} '
                    'ภายใน ${cluster.windowDays} วัน',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'รายแรก: ${_fmt(cluster.firstReport)}  ·  ล่าสุด: ${_fmt(cluster.lastReport)}',
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) => DateFormat('d MMM', 'th').format(d);
}

class _ReportTile extends StatelessWidget {
  final CommunityReport report;
  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final isDisease = report.kind == ReportKind.disease;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isDisease ? Icons.local_florist : Icons.bug_report,
          color: isDisease ? AppColors.error : AppColors.warning,
        ),
        title: Text(report.conditionNameTh),
        subtitle: Text(
          '${report.provinceTh ?? report.geohash5} · ${DateFormat('d MMM HH:mm', 'th').format(report.reportedAt)}',
        ),
        trailing: Text('${(report.confidence * 100).toStringAsFixed(0)}%'),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(
          'ยังไม่มีรายงานในชุมชน ลองใช้ฟีเจอร์วินิจฉัยโรคหรือศัตรูพืชก่อนครับ',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
