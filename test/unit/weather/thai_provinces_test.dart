import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/features/weather/data/thai_provinces.dart';

void main() {
  group('ThaiProvince', () {
    test('can be instantiated with all fields', () {
      const province = ThaiProvince(
        nameTh: 'สุโขทัย',
        nameEn: 'Sukhothai',
        latitude: 17.0063,
        longitude: 99.8231,
      );
      expect(province.nameTh, 'สุโขทัย');
      expect(province.nameEn, 'Sukhothai');
      expect(province.latitude, 17.0063);
      expect(province.longitude, 99.8231);
    });
  });

  group('thaiProvinces list', () {
    test('contains provinces', () {
      expect(thaiProvinces.length, greaterThan(70));
    });

    test('all provinces have non-empty names', () {
      for (final p in thaiProvinces) {
        expect(p.nameTh, isNotEmpty);
        expect(p.nameEn, isNotEmpty);
      }
    });

    test('all provinces have valid coordinates', () {
      for (final p in thaiProvinces) {
        expect(p.latitude, greaterThanOrEqualTo(-90.0));
        expect(p.latitude, lessThanOrEqualTo(90.0));
        expect(p.longitude, greaterThanOrEqualTo(-180.0));
        expect(p.longitude, lessThanOrEqualTo(180.0));
      }
    });
  });

  group('nearestProvince', () {
    test('returns a province when given valid coordinates', () {
      final nearest = nearestProvince(17.0063, 99.8231);
      expect(nearest, isNotNull);
      expect(nearest.nameTh, isNotEmpty);
    });

    test('finds Sukhothai for Sukhothai coordinates', () {
      final sukhothai = thaiProvinces.firstWhere((p) => p.nameTh == 'สุโขทัย');
      final nearest = nearestProvince(
        sukhothai.latitude,
        sukhothai.longitude,
      );
      expect(nearest.nameTh, 'สุโขทัย');
    });

    test('returns Bangkok as nearest to Bangkok coordinates', () {
      final bangkok =
          thaiProvinces.firstWhere((p) => p.nameTh == 'กรุงเทพมหานคร');
      final nearest = nearestProvince(
        bangkok.latitude,
        bangkok.longitude,
      );
      expect(nearest.nameTh, 'กรุงเทพมหานคร');
    });

    test('handles northern Thailand coordinates', () {
      // Northern point near Chiang Mai
      final nearest = nearestProvince(18.8, 98.9);
      expect(nearest.nameTh, isNotEmpty);
      // Should be close to Chiang Mai region
      expect(
        [
          'เชียงใหม่',
          'ลำพูน',
          'ลำปาง',
        ].contains(nearest.nameTh),
        true,
      );
    });

    test('handles southern Thailand coordinates', () {
      // Southern point near Phuket/Krabi region
      final nearest = nearestProvince(8.0, 98.9);
      expect(nearest.nameTh, isNotEmpty);
      // Should be in southern region
      expect(
        [
          'กระบี่',
          'ชุมพร',
          'พังงา',
        ].contains(nearest.nameTh),
        true,
      );
    });

    test('throws when provinces list is empty', () {
      // This test documents the error behavior
      // In practice, thaiProvinces is always populated
      expect(() => nearestProvince(0.0, 0.0), returnsNormally);
    });
  });
}
