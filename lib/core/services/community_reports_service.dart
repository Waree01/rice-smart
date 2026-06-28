import 'dart:convert';

import 'package:dart_geohash/dart_geohash.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/community_report.dart';

/// Storage + clustering for community disease/pest reports.
///
/// This implementation uses a SharedPreferences-backed local store so
/// the feature works offline and without Firebase credentials. When a
/// real Firestore project is configured the persistence layer can be
/// swapped — the public API stays the same.
///
/// The geohash precision (5) is chosen for Thai rice provinces: each
/// cell covers ~4.9 km × 4.9 km which is small enough to be actionable
/// but large enough to avoid pinpointing an individual farm.
class CommunityReportsService {
  CommunityReportsService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  final _geo = GeoHasher();
  static const _uuid = Uuid();
  static const _key = 'community_reports_v1';

  /// Record a new observation. [lat]/[lon] are anonymized to a geohash
  /// before storage.
  Future<CommunityReport> submit({
    required ReportKind kind,
    required String conditionId,
    required String conditionNameTh,
    required double confidence,
    required double lat,
    required double lon,
    String? provinceTh,
  }) async {
    final geohash = _geo.encode(lon, lat, precision: 5);
    final report = CommunityReport(
      id: _uuid.v4(),
      kind: kind,
      conditionId: conditionId,
      conditionNameTh: conditionNameTh,
      confidence: confidence,
      geohash5: geohash,
      provinceTh: provinceTh,
      reportedAt: DateTime.now(),
    );
    final all = await _loadAll();
    all.add(report);
    await _saveAll(all);
    _logger.i('Community report saved (${report.conditionId} @ $geohash)');
    return report;
  }

  /// Every report on disk, newest first.
  Future<List<CommunityReport>> all() async {
    final out = await _loadAll();
    out.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return out;
  }

  /// Detect "hot" clusters — same condition, same geohash-5 cell, ≥3
  /// reports, within a 14-day window. Returns the newest first.
  Future<List<OutbreakCluster>> detectOutbreaks({
    Duration window = const Duration(days: 14),
  }) async {
    final reports = await _loadAll();
    if (reports.isEmpty) return const [];
    final cutoff = DateTime.now().subtract(window);

    final buckets = <String, List<CommunityReport>>{};
    for (final r in reports.where((r) => r.reportedAt.isAfter(cutoff))) {
      final key = '${r.geohash5}|${r.conditionId}';
      buckets.putIfAbsent(key, () => []).add(r);
    }

    final clusters = <OutbreakCluster>[];
    for (final entry in buckets.entries) {
      final parts = entry.key.split('|');
      final items = entry.value
        ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));
      final cluster = OutbreakCluster(
        geohashPrefix: parts[0],
        conditionId: parts[1],
        conditionNameTh: items.first.conditionNameTh,
        reportCount: items.length,
        firstReport: items.first.reportedAt,
        lastReport: items.last.reportedAt,
        provinceTh: items.first.provinceTh,
      );
      if (cluster.isHot) clusters.add(cluster);
    }
    clusters.sort((a, b) => b.lastReport.compareTo(a.lastReport));
    return clusters;
  }

  /// Seed a demo outbreak cluster (rice blast around Pathum Thani) so
  /// the admin map + outbreak screens have data to render in a thesis
  /// demo. No-op if any report already exists.
  Future<void> seedDemoIfEmpty() async {
    final existing = await _loadAll();
    if (existing.isNotEmpty) return;

    // คลองหลวง ปทุมธานี — points jitter inside one ~5 km cell so they
    // cluster into a single hot OutbreakCluster.
    const baseLat = 14.07;
    const baseLon = 100.62;
    final now = DateTime.now();
    final reports = <CommunityReport>[];
    for (var i = 0; i < 14; i++) {
      final lat = baseLat + ((i % 5) - 2) * 0.006;
      final lon = baseLon + ((i % 4) - 2) * 0.006;
      reports.add(
        CommunityReport(
          id: _uuid.v4(),
          kind: ReportKind.disease,
          conditionId: 'rice_blast',
          conditionNameTh: 'โรคไหม้ข้าว',
          confidence: 0.86 + (i % 5) * 0.02,
          geohash5: _geo.encode(lon, lat, precision: 5),
          provinceTh: 'ปทุมธานี',
          reportedAt: now.subtract(Duration(days: i % 7, hours: i)),
        ),
      );
    }
    // A smaller, watch-level pest cluster nearby.
    for (var i = 0; i < 2; i++) {
      reports.add(
        CommunityReport(
          id: _uuid.v4(),
          kind: ReportKind.pest,
          conditionId: 'brown_planthopper',
          conditionNameTh: 'เพลี้ยกระโดดสีน้ำตาล',
          confidence: 0.80,
          geohash5: _geo.encode(baseLon + 0.05, baseLat + 0.05, precision: 5),
          provinceTh: 'ปทุมธานี',
          reportedAt: now.subtract(Duration(days: i + 1)),
        ),
      );
    }
    await _saveAll(reports);
    _logger.i('Seeded ${reports.length} demo community reports');
  }

  /// Clear all community reports stored on this device.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<List<CommunityReport>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(CommunityReport.fromJson)
          .toList();
    } catch (e) {
      _logger.w('Community report parse failed; starting fresh', error: e);
      return [];
    }
  }

  Future<void> _saveAll(List<CommunityReport> reports) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(reports.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
