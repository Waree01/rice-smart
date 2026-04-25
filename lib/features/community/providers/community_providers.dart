import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/community_reports_service.dart';
import '../../../models/community_report.dart';

final communityReportsServiceProvider =
    Provider<CommunityReportsService>((ref) => CommunityReportsService());

final recentReportsProvider =
    FutureProvider<List<CommunityReport>>((ref) async {
  return ref.watch(communityReportsServiceProvider).all();
});

final outbreakClustersProvider =
    FutureProvider<List<OutbreakCluster>>((ref) async {
  return ref.watch(communityReportsServiceProvider).detectOutbreaks();
});
