/// An outbreak warning an admin has broadcast to farmers in an area.
///
/// Created on screen 12 (ยืนยัน + กระจายเตือน) from a hot
/// [OutbreakCluster], then surfaced as the red banner on the farmer
/// dashboard (screen 13).
class OutbreakAlert {
  final String id;
  final String conditionId;
  final String conditionNameTh;

  /// Human-readable affected area, e.g. "อ.คลองหลวง ปทุมธานี".
  final String areaLabel;
  final String? provinceTh;

  final double radiusKm;
  final int pointCount;

  /// Message shown to farmers.
  final String message;

  final DateTime broadcastAt;
  final bool active;

  const OutbreakAlert({
    required this.id,
    required this.conditionId,
    required this.conditionNameTh,
    required this.areaLabel,
    required this.radiusKm,
    required this.pointCount,
    required this.message,
    required this.broadcastAt,
    this.provinceTh,
    this.active = true,
  });

  OutbreakAlert copyWith({bool? active}) => OutbreakAlert(
        id: id,
        conditionId: conditionId,
        conditionNameTh: conditionNameTh,
        areaLabel: areaLabel,
        provinceTh: provinceTh,
        radiusKm: radiusKm,
        pointCount: pointCount,
        message: message,
        broadcastAt: broadcastAt,
        active: active ?? this.active,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conditionId': conditionId,
        'conditionNameTh': conditionNameTh,
        'areaLabel': areaLabel,
        'provinceTh': provinceTh,
        'radiusKm': radiusKm,
        'pointCount': pointCount,
        'message': message,
        'broadcastAt': broadcastAt.toIso8601String(),
        'active': active,
      };

  factory OutbreakAlert.fromJson(Map<String, dynamic> json) => OutbreakAlert(
        id: json['id'] as String,
        conditionId: json['conditionId'] as String,
        conditionNameTh: json['conditionNameTh'] as String,
        areaLabel: json['areaLabel'] as String,
        provinceTh: json['provinceTh'] as String?,
        radiusKm: (json['radiusKm'] as num).toDouble(),
        pointCount: (json['pointCount'] as num).toInt(),
        message: json['message'] as String,
        broadcastAt: DateTime.parse(json['broadcastAt'] as String),
        active: json['active'] as bool? ?? true,
      );
}
