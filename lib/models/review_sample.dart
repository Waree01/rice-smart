import 'community_report.dart' show ReportKind;

/// One image awaiting human review in the active-learning loop.
///
/// Samples land here when the on-device classifier is *unsure* (low
/// confidence). An admin then confirms or corrects the label, and the
/// corrected pair becomes training data for the next model revision.
enum ReviewStatus { pending, labeled, skipped }

class ReviewSample {
  final String id;
  final ReportKind kind;

  /// Local path to the captured image (may be missing on a fresh device
  /// or for seeded demo rows — the UI falls back to an icon).
  final String? imagePath;

  /// What the model guessed, and how sure it was (0..1).
  final String aiGuessId;
  final String aiGuessTh;
  final double confidence;

  final ReviewStatus status;

  /// Canonical label id chosen by the admin (null until reviewed).
  final String? correctedLabelId;

  final DateTime createdAt;
  final DateTime? reviewedAt;

  const ReviewSample({
    required this.id,
    required this.kind,
    required this.aiGuessId,
    required this.aiGuessTh,
    required this.confidence,
    required this.createdAt,
    this.imagePath,
    this.status = ReviewStatus.pending,
    this.correctedLabelId,
    this.reviewedAt,
  });

  bool get isPest => kind == ReportKind.pest;

  /// True when the admin's label disagreed with the model — i.e. the
  /// model would have been wrong. Useful for accuracy stats.
  bool get wasCorrection =>
      status == ReviewStatus.labeled && correctedLabelId != aiGuessId;

  ReviewSample copyWith({
    ReviewStatus? status,
    String? correctedLabelId,
    DateTime? reviewedAt,
  }) {
    return ReviewSample(
      id: id,
      kind: kind,
      imagePath: imagePath,
      aiGuessId: aiGuessId,
      aiGuessTh: aiGuessTh,
      confidence: confidence,
      createdAt: createdAt,
      status: status ?? this.status,
      correctedLabelId: correctedLabelId ?? this.correctedLabelId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'imagePath': imagePath,
        'aiGuessId': aiGuessId,
        'aiGuessTh': aiGuessTh,
        'confidence': confidence,
        'status': status.name,
        'correctedLabelId': correctedLabelId,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  factory ReviewSample.fromJson(Map<String, dynamic> json) => ReviewSample(
        id: json['id'] as String,
        kind: ReportKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => ReportKind.disease,
        ),
        imagePath: json['imagePath'] as String?,
        aiGuessId: json['aiGuessId'] as String,
        aiGuessTh: json['aiGuessTh'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        status: ReviewStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ReviewStatus.pending,
        ),
        correctedLabelId: json['correctedLabelId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewedAt: json['reviewedAt'] == null
            ? null
            : DateTime.parse(json['reviewedAt'] as String),
      );
}
