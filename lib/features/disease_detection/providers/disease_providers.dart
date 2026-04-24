import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/disease_result.dart';
import '../services/disease_inference_service.dart';

/// Shared inference service provider (singleton per ProviderScope).
final diseaseInferenceServiceProvider =
    Provider<DiseaseInferenceService>((ref) => DiseaseInferenceService());

/// Async state for the last disease-detection run.
/// `null` = idle, `AsyncLoading` = running, `AsyncData` = result,
/// `AsyncError` = failure.
class DiseaseDetectionController
    extends StateNotifier<AsyncValue<DiseaseResult?>> {
  DiseaseDetectionController(this._service)
      : super(const AsyncValue.data(null));

  final DiseaseInferenceService _service;

  Future<void> analyze(String imagePath) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.classify(imagePath: imagePath);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final diseaseDetectionControllerProvider = StateNotifierProvider<
    DiseaseDetectionController, AsyncValue<DiseaseResult?>>((ref) {
  return DiseaseDetectionController(ref.watch(diseaseInferenceServiceProvider));
});
