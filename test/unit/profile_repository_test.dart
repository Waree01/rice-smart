import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/data/profile_repository.dart';
import 'package:rice_smart/models/farmer_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileRepository', () {
    test('returns null when nothing is stored', () async {
      expect(await ProfileRepository().load(), isNull);
    });

    test('save + load round-trips', () async {
      final repo = ProfileRepository();
      await repo.save(
        const FarmerProfile(
          id: 'u1',
          name: 'ลุงสมชาย',
          provinceTh: 'สุโขทัย',
          farmSizeRai: 15,
          preferredLlm: 'typhoon',
        ),
      );
      final loaded = await repo.load();
      expect(loaded, isNotNull);
      expect(loaded!.name, 'ลุงสมชาย');
      expect(loaded.provinceTh, 'สุโขทัย');
      expect(loaded.farmSizeRai, 15);
    });

    test('clear removes stored profile', () async {
      final repo = ProfileRepository();
      await repo.save(const FarmerProfile(id: 'x', name: 'X'));
      await repo.clear();
      expect(await repo.load(), isNull);
    });
  });
}
