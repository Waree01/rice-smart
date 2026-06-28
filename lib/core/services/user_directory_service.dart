import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_user.dart';

/// Local store for the admin user directory (screen 10).
///
/// SharedPreferences-backed for the demo; seeded with a handful of
/// representative accounts so the screen isn't empty on first run.
class UserDirectoryService {
  UserDirectoryService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  static const _uuid = Uuid();
  static const _key = 'user_directory_v1';

  Future<List<AppUser>> all() async => _loadAll();

  /// Suspend / reactivate an account.
  Future<void> setStatus(String id, UserStatus status) async {
    final all = await _loadAll();
    final idx = all.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(status: status);
    await _saveAll(all);
  }

  /// Grant / revoke admin rights.
  Future<void> setRole(String id, UserRole role) async {
    final all = await _loadAll();
    final idx = all.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(role: role);
    await _saveAll(all);
  }

  Future<AppUser> addAdmin(String name, {String? provinceTh}) async {
    final user = AppUser(
      id: _uuid.v4(),
      name: name,
      provinceTh: provinceTh,
      role: UserRole.admin,
    );
    final all = await _loadAll();
    all.insert(0, user);
    await _saveAll(all);
    return user;
  }

  /// Seed the demo directory once. No-op if it already has data.
  Future<void> seedIfEmpty() async {
    final existing = await _loadAll();
    if (existing.isNotEmpty) return;
    final seed = <AppUser>[
      const AppUser(id: 'u_somchai', name: 'ลุงสมชาย', provinceTh: 'ปทุมธานี'),
      const AppUser(id: 'u_malee', name: 'ป้ามาลี', provinceTh: 'สุพรรณบุรี'),
      const AppUser(
        id: 'u_wittaya',
        name: 'วิทยา (จนท.)',
        provinceTh: 'ปทุมธานี',
        role: UserRole.admin,
        labelCount: 320,
      ),
      const AppUser(
        id: 'u_noknoi',
        name: 'นกน้อย',
        provinceTh: 'อยุธยา',
        status: UserStatus.suspended,
      ),
    ];
    await _saveAll(seed);
    _logger.i('Seeded ${seed.length} demo users');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<List<AppUser>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>().map(AppUser.fromJson).toList();
    } catch (e) {
      _logger.w('User directory parse failed; starting fresh', error: e);
      return [];
    }
  }

  Future<void> _saveAll(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(users.map((u) => u.toJson()).toList()),
    );
  }
}
