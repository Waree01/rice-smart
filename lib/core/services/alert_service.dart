import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/outbreak_alert.dart';

/// Store for outbreak alerts that admins broadcast to farmers.
///
/// SharedPreferences-backed for the demo. Broadcasting writes an alert
/// here; the farmer dashboard reads [active] alerts and shows the red
/// warning banner. With Firebase wired, [broadcast] would also push an
/// FCM topic message to the affected area.
class AlertService {
  AlertService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  static const _uuid = Uuid();
  static const _key = 'outbreak_alerts_v1';

  /// Publish a new outbreak alert (admin action, screen 12).
  Future<OutbreakAlert> broadcast({
    required String conditionId,
    required String conditionNameTh,
    required String areaLabel,
    required double radiusKm,
    required int pointCount,
    required String message,
    String? provinceTh,
  }) async {
    final alert = OutbreakAlert(
      id: _uuid.v4(),
      conditionId: conditionId,
      conditionNameTh: conditionNameTh,
      areaLabel: areaLabel,
      provinceTh: provinceTh,
      radiusKm: radiusKm,
      pointCount: pointCount,
      message: message,
      broadcastAt: DateTime.now(),
    );
    final all = await _loadAll();
    all.add(alert);
    await _saveAll(all);
    _logger.i('Outbreak alert broadcast ($conditionId @ $areaLabel)');
    return alert;
  }

  /// Active alerts, newest first.
  Future<List<OutbreakAlert>> active() async {
    final out = await _loadAll();
    out
      ..removeWhere((a) => !a.active)
      ..sort((a, b) => b.broadcastAt.compareTo(a.broadcastAt));
    return out;
  }

  Future<List<OutbreakAlert>> all() async {
    final out = await _loadAll();
    out.sort((a, b) => b.broadcastAt.compareTo(a.broadcastAt));
    return out;
  }

  /// Close a case — stops showing the banner to farmers.
  Future<void> dismiss(String id) async {
    final all = await _loadAll();
    final idx = all.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(active: false);
    await _saveAll(all);
  }

  /// Whether an active alert already exists for this condition+area, so
  /// the admin UI can mark a cluster as "already broadcast".
  Future<bool> hasActiveFor(String conditionId, String areaLabel) async {
    final list = await active();
    return list
        .any((a) => a.conditionId == conditionId && a.areaLabel == areaLabel);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<List<OutbreakAlert>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(OutbreakAlert.fromJson)
          .toList();
    } catch (e) {
      _logger.w('Alert store parse failed; starting fresh', error: e);
      return [];
    }
  }

  Future<void> _saveAll(List<OutbreakAlert> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(alerts.map((a) => a.toJson()).toList()),
    );
  }
}
