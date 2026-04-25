import 'package:flutter_test/flutter_test.dart';
import 'package:rice_smart/core/services/community_reports_service.dart';
import 'package:rice_smart/models/community_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CommunityReportsService', () {
    test('submit + all round-trip', () async {
      final service = CommunityReportsService();
      final r = await service.submit(
        kind: ReportKind.disease,
        conditionId: 'rice_blast',
        conditionNameTh: 'โรคไหม้',
        confidence: 0.92,
        lat: 17.006,
        lon: 99.823,
        provinceTh: 'สุโขทัย',
      );
      expect(r.geohash5, hasLength(5));

      final all = await service.all();
      expect(all, hasLength(1));
      expect(all.first.conditionId, 'rice_blast');
      expect(all.first.provinceTh, 'สุโขทัย');
    });

    test('detectOutbreaks requires 3+ reports in same cell', () async {
      final service = CommunityReportsService();
      // Same lat/lon so all three land in the same geohash-5 cell.
      for (var i = 0; i < 3; i++) {
        await service.submit(
          kind: ReportKind.disease,
          conditionId: 'rice_blast',
          conditionNameTh: 'โรคไหม้',
          confidence: 0.9,
          lat: 17.006,
          lon: 99.823,
          provinceTh: 'สุโขทัย',
        );
      }
      final clusters = await service.detectOutbreaks();
      expect(clusters, hasLength(1));
      final c = clusters.first;
      expect(c.reportCount, 3);
      expect(c.conditionId, 'rice_blast');
      expect(c.isHot, true);
    });

    test('detectOutbreaks ignores single reports', () async {
      final service = CommunityReportsService();
      await service.submit(
        kind: ReportKind.disease,
        conditionId: 'brown_spot',
        conditionNameTh: 'ใบจุดสีน้ำตาล',
        confidence: 0.8,
        lat: 17.0,
        lon: 99.0,
      );
      expect(await service.detectOutbreaks(), isEmpty);
    });

    test('clear() wipes storage', () async {
      final service = CommunityReportsService();
      await service.submit(
        kind: ReportKind.pest,
        conditionId: 'brown_planthopper',
        conditionNameTh: 'เพลี้ยกระโดดสีน้ำตาล',
        confidence: 0.88,
        lat: 17.0,
        lon: 99.0,
      );
      await service.clear();
      expect(await service.all(), isEmpty);
    });
  });
}
