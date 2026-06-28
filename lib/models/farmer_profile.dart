/// User profile stored locally (and optionally synced to Firestore).
class FarmerProfile {
  final String id;
  final String name;
  final String? provinceTh;
  final double? latitude;
  final double? longitude;

  /// Area under cultivation in Thai rai.
  final double? farmSizeRai;

  /// Preferred LLM provider id for Pasadee ('typhoon' default).
  final String preferredLlm;

  /// UI language ('th' / 'en').
  final String language;

  /// Access role: `'user'` (farmer, default) or `'admin'` (เจ้าหน้าที่
  /// ควบคุมคุณภาพ + ติดป้ายข้อมูล). Gates the admin-side screens.
  final String role;

  const FarmerProfile({
    required this.id,
    required this.name,
    this.provinceTh,
    this.latitude,
    this.longitude,
    this.farmSizeRai,
    this.preferredLlm = 'typhoon',
    this.language = 'th',
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  FarmerProfile copyWith({
    String? name,
    String? provinceTh,
    double? latitude,
    double? longitude,
    double? farmSizeRai,
    String? preferredLlm,
    String? language,
    String? role,
  }) {
    return FarmerProfile(
      id: id,
      name: name ?? this.name,
      provinceTh: provinceTh ?? this.provinceTh,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      farmSizeRai: farmSizeRai ?? this.farmSizeRai,
      preferredLlm: preferredLlm ?? this.preferredLlm,
      language: language ?? this.language,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provinceTh': provinceTh,
        'latitude': latitude,
        'longitude': longitude,
        'farmSizeRai': farmSizeRai,
        'preferredLlm': preferredLlm,
        'language': language,
        'role': role,
      };

  factory FarmerProfile.fromJson(Map<String, dynamic> json) => FarmerProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        provinceTh: json['provinceTh'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        farmSizeRai: (json['farmSizeRai'] as num?)?.toDouble(),
        preferredLlm: json['preferredLlm'] as String? ?? 'typhoon',
        language: json['language'] as String? ?? 'th',
        role: json['role'] as String? ?? 'user',
      );
}
