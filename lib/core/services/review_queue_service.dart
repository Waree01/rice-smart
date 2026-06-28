import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/community_report.dart' show ReportKind;
import '../../models/review_sample.dart';

/// Local store + active-learning queue for low-confidence detections.
///
/// Mirrors [CommunityReportsService]: SharedPreferences-backed so the
/// admin tooling works offline and without Firebase. When the real
/// backend is provisioned the persistence layer can be swapped while the
/// public API stays the same.
class ReviewQueueService {
  ReviewQueueService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  static const _uuid = Uuid();
  static const _key = 'review_queue_v1';

  /// Add a sample the classifier was unsure about, to be reviewed later.
  Future<ReviewSample> enqueue({
    required ReportKind kind,
    required String aiGuessId,
    required String aiGuessTh,
    required double confidence,
    String? imagePath,
  }) async {
    final sample = ReviewSample(
      id: _uuid.v4(),
      kind: kind,
      imagePath: imagePath,
      aiGuessId: aiGuessId,
      aiGuessTh: aiGuessTh,
      confidence: confidence,
      createdAt: DateTime.now(),
    );
    final all = await _loadAll();
    all.add(sample);
    await _saveAll(all);
    _logger.i(
      'Review sample queued ($aiGuessId @ ${(confidence * 100).round()}%)',
    );
    return sample;
  }

  /// Every sample on disk, newest first.
  Future<List<ReviewSample>> all() async {
    final out = await _loadAll();
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  /// Samples still awaiting review, oldest first (FIFO labelling order).
  Future<List<ReviewSample>> pending() async {
    final out = await _loadAll();
    out
      ..removeWhere((s) => s.status != ReviewStatus.pending)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  /// Confirm/correct a sample's label, marking it reviewed.
  Future<void> label(String id, String correctedLabelId) async {
    final all = await _loadAll();
    final idx = all.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(
      status: ReviewStatus.labeled,
      correctedLabelId: correctedLabelId,
      reviewedAt: DateTime.now(),
    );
    await _saveAll(all);
  }

  /// Skip a sample (e.g. unclear image) without producing a label.
  Future<void> skip(String id) async {
    final all = await _loadAll();
    final idx = all.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(
      status: ReviewStatus.skipped,
      reviewedAt: DateTime.now(),
    );
    await _saveAll(all);
  }

  /// Aggregate counts for the admin dashboard.
  Future<ReviewStats> stats() async {
    final all = await _loadAll();
    final today = DateTime.now();
    final pending = all.where((s) => s.status == ReviewStatus.pending).length;
    final labeledToday = all.where((s) {
      return s.status == ReviewStatus.labeled &&
          s.reviewedAt != null &&
          _sameDay(s.reviewedAt!, today);
    }).length;
    final labeled = all.where((s) => s.status == ReviewStatus.labeled).toList();
    final agree = labeled.where((s) => !s.wasCorrection).length;
    final accuracy = labeled.isEmpty ? null : agree / labeled.length;
    return ReviewStats(
      pending: pending,
      labeledToday: labeledToday,
      totalLabeled: labeled.length,
      modelAccuracy: accuracy,
    );
  }

  /// Seed demo samples on a fresh device so the admin screens have
  /// something to show in a thesis demo. No-op if the queue is non-empty.
  Future<void> seedIfEmpty(List<ReviewSample> samples) async {
    final existing = await _loadAll();
    if (existing.isNotEmpty) return;
    await _saveAll(samples);
    _logger.i('Seeded ${samples.length} demo review samples');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<List<ReviewSample>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(ReviewSample.fromJson)
          .toList();
    } catch (e) {
      _logger.w('Review queue parse failed; starting fresh', error: e);
      return [];
    }
  }

  Future<void> _saveAll(List<ReviewSample> samples) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(samples.map((s) => s.toJson()).toList()),
    );
  }
}

/// Snapshot of queue counts shown on the admin dashboard.
class ReviewStats {
  final int pending;
  final int labeledToday;
  final int totalLabeled;

  /// Fraction of reviewed samples where the model already agreed with
  /// the human (0..1), or null if nothing has been labelled yet.
  final double? modelAccuracy;

  const ReviewStats({
    required this.pending,
    required this.labeledToday,
    required this.totalLabeled,
    this.modelAccuracy,
  });
}
