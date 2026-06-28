import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/community_reports_service.dart';
import '../../../models/community_report.dart';
import '../../../models/disease_result.dart';
import '../../admin/providers/admin_providers.dart';
import '../../community/providers/community_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../services/disease_inference_service.dart';

/// Shared inference service provider (singleton per ProviderScope).
final diseaseInferenceServiceProvider =
    Provider<DiseaseInferenceService>((ref) => DiseaseInferenceService());

/// Async state for the last disease-detection run.
/// `null` = idle, `AsyncLoading` = running, `AsyncData` = result,
/// `AsyncError` = failure.
class DiseaseDetectionController
    extends StateNotifier<AsyncValue<DiseaseResult?>> {
  DiseaseDetectionController(this._service, this._reports, this._ref)
      : super(const AsyncValue.data(null));

  final DiseaseInferenceService _service;
  final CommunityReportsService _reports;
  final Ref _ref;

  Future<void> analyze(String imagePath) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.classify(imagePath: imagePath);
      state = AsyncValue.data(result);
      await _maybeReportToCommunity(result);
      await _maybeQueueForReview(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  /// Send detections the model was *unsure* about (< 75%) to the admin
  /// review queue, where they fuel the active-learning labelling loop.
  Future<void> _maybeQueueForReview(DiseaseResult result) async {
    if (result.confidence >= 0.75) return;
    await _ref.read(reviewQueueServiceProvider).enqueue(
          kind: ReportKind.disease,
          aiGuessId: _conditionIdFor(result),
          aiGuessTh: result.diseaseName,
          confidence: result.confidence,
          imagePath: result.imagePath,
        );
  }

  /// Auto-share detections ≥ 75% confidence to the community feed so
  /// the outbreak clustering has data. `healthy` is never reported.
  Future<void> _maybeReportToCommunity(DiseaseResult result) async {
    if (result.confidence < 0.75) return;
    if (result.diseaseNameEn.toLowerCase().contains('healthy')) return;
    final profile = _ref.read(profileControllerProvider);
    final lat = profile?.latitude ?? 17.006; // default: Sukhothai
    final lon = profile?.longitude ?? 99.823;
    await _reports.submit(
      kind: ReportKind.disease,
      conditionId: _conditionIdFor(result),
      conditionNameTh: result.diseaseName,
      confidence: result.confidence,
      lat: lat,
      lon: lon,
      provinceTh: profile?.provinceTh,
    );
    _ref.invalidate(recentReportsProvider);
    _ref.invalidate(outbreakClustersProvider);
  }

  String _conditionIdFor(DiseaseResult r) {
    switch (r.diseaseNameEn) {
      case 'Rice Blast':
        return 'rice_blast';
      case 'Brown Spot':
        return 'brown_spot';
      case 'Bacterial Leaf Blight':
        return 'bacterial_leaf_blight';
      case 'Sheath Blight':
        return 'sheath_blight';
      default:
        return r.diseaseNameEn.toLowerCase().replaceAll(' ', '_');
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final diseaseDetectionControllerProvider = StateNotifierProvider<
    DiseaseDetectionController, AsyncValue<DiseaseResult?>>((ref) {
  return DiseaseDetectionController(
    ref.watch(diseaseInferenceServiceProvider),
    ref.watch(communityReportsServiceProvider),
    ref,
  );
});
