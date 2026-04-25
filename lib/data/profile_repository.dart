import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/farmer_profile.dart';

/// Persistence for a single [FarmerProfile].
///
/// Uses SharedPreferences keyed under `farmer_profile_v1` so a
/// future schema bump can land on a new key without migration code.
class ProfileRepository {
  static const _key = 'farmer_profile_v1';

  Future<FarmerProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return FarmerProfile.fromJson(
          json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(FarmerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(profile.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
