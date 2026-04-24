import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/pest_result.dart';
import '../services/pest_inference_service.dart';

final pestInferenceServiceProvider =
    Provider<PestInferenceService>((ref) => PestInferenceService());

class PestDetectionController
    extends StateNotifier<AsyncValue<PestResult?>> {
  PestDetectionController(this._service) : super(const AsyncValue.data(null));
  final PestInferenceService _service;

  Future<void> analyze(String imagePath) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.detect(imagePath: imagePath);
      state = AsyncValue.data(result);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final pestDetectionControllerProvider = StateNotifierProvider<
    PestDetectionController, AsyncValue<PestResult?>>((ref) {
  return PestDetectionController(ref.watch(pestInferenceServiceProvider));
});
