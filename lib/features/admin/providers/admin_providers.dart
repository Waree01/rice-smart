import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/alert_service.dart';
import '../../../core/services/review_queue_service.dart';
import '../../../core/services/user_directory_service.dart';
import '../../../models/app_user.dart';
import '../../../models/community_report.dart';
import '../../../models/outbreak_alert.dart';
import '../../../models/review_sample.dart';
import '../../community/providers/community_providers.dart';

// ── Services ────────────────────────────────────────────────────────────
final reviewQueueServiceProvider =
    Provider<ReviewQueueService>((ref) => ReviewQueueService());

final userDirectoryServiceProvider =
    Provider<UserDirectoryService>((ref) => UserDirectoryService());

final alertServiceProvider = Provider<AlertService>((ref) => AlertService());

// ── Derived state ───────────────────────────────────────────────────────
final reviewStatsProvider = FutureProvider<ReviewStats>((ref) async {
  return ref.watch(reviewQueueServiceProvider).stats();
});

final pendingReviewProvider = FutureProvider<List<ReviewSample>>((ref) async {
  return ref.watch(reviewQueueServiceProvider).pending();
});

final usersProvider = FutureProvider<List<AppUser>>((ref) async {
  return ref.watch(userDirectoryServiceProvider).all();
});

final activeAlertsProvider = FutureProvider<List<OutbreakAlert>>((ref) async {
  return ref.watch(alertServiceProvider).active();
});

/// Invalidate everything the admin dashboard reads after a mutation.
void refreshAdmin(WidgetRef ref) {
  ref.invalidate(reviewStatsProvider);
  ref.invalidate(pendingReviewProvider);
  ref.invalidate(usersProvider);
  ref.invalidate(activeAlertsProvider);
  ref.invalidate(outbreakClustersProvider);
  ref.invalidate(recentReportsProvider);
}

/// One-shot demo seeding so the admin side has data on a fresh device.
/// Idempotent — each service seeds only when its own store is empty.
final adminSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(communityReportsServiceProvider).seedDemoIfEmpty();
  await ref.watch(userDirectoryServiceProvider).seedIfEmpty();
  await ref.watch(reviewQueueServiceProvider).seedIfEmpty(_demoReviewSamples());
});

List<ReviewSample> _demoReviewSamples() {
  final now = DateTime.now();
  ReviewSample s(
    String id,
    ReportKind kind,
    String aiId,
    String aiTh,
    double conf,
    int minsAgo,
  ) =>
      ReviewSample(
        id: id,
        kind: kind,
        aiGuessId: aiId,
        aiGuessTh: aiTh,
        confidence: conf,
        createdAt: now.subtract(Duration(minutes: minsAgo)),
      );

  return [
    s('rv_1', ReportKind.disease, 'rice_blast', 'โรคไหม้ข้าว', 0.61, 30),
    s(
      'rv_2',
      ReportKind.pest,
      'brown_planthopper',
      'เพลี้ยกระโดดสีน้ำตาล',
      0.58,
      90,
    ),
    s('rv_3', ReportKind.disease, 'brown_spot', 'ใบจุดสีน้ำตาล', 0.64, 150),
    s('rv_4', ReportKind.disease, 'healthy', 'ไม่ชัดเจน', 0.40, 240),
  ];
}
