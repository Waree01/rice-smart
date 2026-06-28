/// A user record in the admin directory (screen 10 — จัดการผู้ใช้).
///
/// This is the admin's *view* of accounts, distinct from the local
/// [FarmerProfile] of the person holding the phone. Backed locally for
/// the demo; swappable for a real users collection later.
enum UserRole { user, admin }

enum UserStatus { active, suspended }

class AppUser {
  final String id;
  final String name;
  final String? provinceTh;
  final UserRole role;
  final UserStatus status;

  /// How many images this user has labelled (admins only).
  final int labelCount;

  const AppUser({
    required this.id,
    required this.name,
    this.provinceTh,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.labelCount = 0,
  });

  AppUser copyWith({UserRole? role, UserStatus? status}) => AppUser(
        id: id,
        name: name,
        provinceTh: provinceTh,
        role: role ?? this.role,
        status: status ?? this.status,
        labelCount: labelCount,
      );

  String get roleLabelTh => role == UserRole.admin ? 'แอดมิน' : 'ผู้ใช้';
  String get statusLabelTh =>
      status == UserStatus.suspended ? 'ระงับ' : 'ใช้งาน';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provinceTh': provinceTh,
        'role': role.name,
        'status': status.name,
        'labelCount': labelCount,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        provinceTh: json['provinceTh'] as String?,
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.user,
        ),
        status: UserStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => UserStatus.active,
        ),
        labelCount: (json['labelCount'] as num?)?.toInt() ?? 0,
      );
}
