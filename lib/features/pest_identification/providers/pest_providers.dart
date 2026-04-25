import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/community_reports_service.dart';
import '../../../models/community_report.dart';
import '../../../models/pest_result.dart';
import '../../community/providers/community_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../services/pest_inference_service.dart';

final pestInferenceServiceProvider =
    Provider<PestInferenceService>((ref) => PestInferenceService());

class PestDetectionController extends StateNotifier<AsyncValue<PestResult?>> {
  PestDetectionController(this._service, this._reports, this._ref)
      : super(const AsyncValue.data(null));

  final PestInferenceService _service;
  final CommunityReportsService _reports;
  final Ref _ref;

  Future<void> analyze(String imagePath) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.detect(imagePath: imagePath);
      state = AsyncValue.data(result);
      await _maybeReportToCommunity(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> _maybeReportToCommunity(PestResult result) async {
    final primary = result.primary;
    if (primary == null || primary.confidence < 0.75) return;
    final profile = _ref.read(profileControllerProvider);
    final lat = profile?.latitude ?? 17.006;
    final lon = profile?.longitude ?? 99.823;
    await _reports.submit(
      kind: ReportKind.pest,
      conditionId: _conditionIdFor(primary.nameEn),
      conditionNameTh: primary.nameTh,
      confidence: primary.confidence,
      lat: lat,
      lon: lon,
      provinceTh: profile?.provinceTh,
    );
    _ref.invalidate(recentReportsProvider);
    _ref.invalidate(outbreakClustersProvider);
  }

  String _conditionIdFor(String nameEn) {
    switch (nameEn) {
      case 'Brown planthopper':
        return 'brown_planthopper';
      case 'Yellow stem borer':
        return 'rice_stem_borer';
      case 'Rice leaffolder':
        return 'rice_leaffolder';
      case 'Rice bug':
        return 'rice_bug';
      case 'Golden apple snail':
        return 'golden_apple_snail';
      default:
        return nameEn.toLowerCase().replaceAll(' ', '_');
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final pestDetectionControllerProvider =
    StateNotifierProvider<PestDetectionController, AsyncValue<PestResult?>>(
        (ref) {
  return PestDetectionController(
    ref.watch(pestInferenceServiceProvider),
    ref.watch(communityReportsServiceProvider),
    ref,
  );
});
