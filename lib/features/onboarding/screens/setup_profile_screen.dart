import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/providers/profile_providers.dart';

/// Display-name + province setup (mockup screen 2).
///
/// Saves a [FarmerProfile] and flips the `onboarding_complete` flag so
/// the dashboard stops redirecting here. Province is optional.
class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Prefill from the name captured during sign-up so the flow continues
    // seamlessly; the user can still edit it here.
    final existing = ref.read(profileControllerProvider);
    if (existing != null && existing.name.isNotEmpty) {
      _nameCtrl.text = existing.name;
      _provinceCtrl.text = existing.provinceTh ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _provinceCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาตั้งชื่อผู้ใช้งานก่อนครับ')),
      );
      return;
    }
    setState(() => _saving = true);
    final province = _provinceCtrl.text.trim();
    await ref.read(profileControllerProvider.notifier).update(
          name: name,
          provinceTh: province.isEmpty ? null : province,
        );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งชื่อผู้ใช้งาน'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.info.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Color(0xFF0F6E56),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ตั้งชื่อที่จะแสดงในแอป\nเปลี่ยนภายหลังได้',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 28),
              const Text(
                'ชื่อผู้ใช้งาน',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'เช่น ลุงสมชาย ชาวนา',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'จังหวัด (ไม่บังคับ)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _provinceCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _finish(),
                decoration: const InputDecoration(
                  hintText: 'เช่น ปทุมธานี',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saving ? null : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('เริ่มใช้งาน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
