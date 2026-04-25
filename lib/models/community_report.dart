/// A single disease/pest observation shared with the community.
///
/// Privacy: we only store the disease/pest *class* + a geohash at
/// precision 5 (~4.9 km cell) + a rough timestamp. No image bytes, no
/// exact coordinates, no user identity leave the device by default.
class CommunityReport {
  final String id;
  final ReportKind kind;

  /// KB id of the condition (e.g. `rice_blast`, `brown_planthopper`).
  final String conditionId;

  /// Localized display name at report time.
  final String conditionNameTh;

  /// Model confidence 0..1.
  final double confidence;

  /// Geohash at precision 5 — roughly 4.9 km × 4.9 km. Coarse enough
  /// to preserve farmer anonymity while still useful for clustering.
  final String geohash5;

  /// Optional human-readable province for UI display.
  final String? provinceTh;

  final DateTime reportedAt;

  const CommunityReport({
    required this.id,
    required this.kind,
    required this.conditionId,
    required this.conditionNameTh,
    required this.confidence,
    required this.geohash5,
    required this.reportedAt,
    this.provinceTh,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'conditionId': conditionId,
        'conditionNameTh': conditionNameTh,
        'confidence': confidence,
        'geohash5': geohash5,
        'provinceTh': provinceTh,
        'reportedAt': reportedAt.toIso8601String(),
      };

  factory CommunityReport.fromJson(Map<String, dynamic> json) =>
      CommunityReport(
        id: json['id'] as String,
        kind: ReportKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => ReportKind.disease,
        ),
        conditionId: json['conditionId'] as String,
        conditionNameTh: json['conditionNameTh'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        geohash5: json['geohash5'] as String,
        provinceTh: json['provinceTh'] as String?,
        reportedAt: DateTime.parse(json['reportedAt'] as String),
      );
}

enum ReportKind { disease, pest }

/// A cluster of reports that indicates a potential outbreak.
class OutbreakCluster {
  final String geohashPrefix;
  final String conditionId;
  final String conditionNameTh;
  final int reportCount;
  final DateTime firstReport;
  final DateTime lastReport;
  final String? provinceTh;

  const OutbreakCluster({
    required this.geohashPrefix,
    required this.conditionId,
    required this.conditionNameTh,
    required this.reportCount,
    required this.firstReport,
    required this.lastReport,
    this.provinceTh,
  });

  /// Days between first and last report — outbreaks that cluster in
  /// time (< 14 days) are more actionable than ambient background.
  int get windowDays => lastReport.difference(firstReport).inDays;

  bool get isHot => reportCount >= 3 && windowDays <= 14;
}
