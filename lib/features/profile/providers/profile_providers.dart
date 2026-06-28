import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/profile_repository.dart';
import '../../../models/farmer_profile.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository());

/// Live profile state. Null until the first `load()` completes or a
/// value is saved. Widgets should treat `null` as "user hasn't set up a
/// profile yet" and surface the setup screen.
class ProfileController extends StateNotifier<FarmerProfile?> {
  ProfileController(this._repo) : super(null) {
    _bootstrap();
  }
  final ProfileRepository _repo;

  Future<void> _bootstrap() async {
    state = await _repo.load();
  }

  Future<void> save(FarmerProfile profile) async {
    await _repo.save(profile);
    state = profile;
  }

  /// Updates part of the current profile, preserving id. Creates a new
  /// profile with a fresh UUID if nothing exists yet.
  Future<void> update({
    String? name,
    String? provinceTh,
    double? latitude,
    double? longitude,
    double? farmSizeRai,
    String? preferredLlm,
    String? language,
    String? role,
  }) async {
    const uuid = Uuid();
    final existing =
        state ?? FarmerProfile(id: uuid.v4(), name: name ?? 'ชาวนา');
    final updated = existing.copyWith(
      name: name,
      provinceTh: provinceTh,
      latitude: latitude,
      longitude: longitude,
      farmSizeRai: farmSizeRai,
      preferredLlm: preferredLlm,
      language: language,
      role: role,
    );
    await save(updated);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = null;
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, FarmerProfile?>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider));
});
