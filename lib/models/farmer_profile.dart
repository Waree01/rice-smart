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

  const FarmerProfile({
    required this.id,
    required this.name,
    this.provinceTh,
    this.latitude,
    this.longitude,
    this.farmSizeRai,
    this.preferredLlm = 'typhoon',
    this.language = 'th',
  });

  FarmerProfile copyWith({
    String? name,
    String? provinceTh,
    double? latitude,
    double? longitude,
    double? farmSizeRai,
    String? preferredLlm,
    String? language,
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
      );
}
