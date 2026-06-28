import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/providers/profile_providers.dart';

/// Admin sign-in — gates the admin-side screens behind an access code.
///
/// On a correct code the current profile is promoted to `role = 'admin'`,
/// onboarding is marked complete, and the admin dashboard opens. The code
/// is [AppConstants.adminAccessCode] for the demo; a real deployment would
/// verify against a backend / Firebase Custom Claims instead.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _codeCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'กรุณากรอกรหัสแอดมิน');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    // Simulate a verification round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (code != AppConstants.adminAccessCode) {
      setState(() {
        _submitting = false;
        _error = 'รหัสแอดมินไม่ถูกต้อง';
      });
      return;
    }

    await ref.read(profileControllerProvider.notifier).update(role: 'admin');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เข้าสู่ระบบแอดมินสำเร็จ'),
        backgroundColor: AppColors.adminPrimary,
        duration: Duration(milliseconds: 1200),
      ),
    );
    context.go('/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบแอดมิน'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 44,
                    color: AppColors.adminPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'สำหรับเจ้าหน้าที่ / แอดมิน',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'กรอกรหัสแอดมินเพื่อเข้าสู่ระบบควบคุมคุณภาพ\nติดป้ายข้อมูล และแผนที่การระบาด',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 28),
              const Text(
                'รหัสแอดมิน',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _codeCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสแอดมิน',
                  prefixIcon: const Icon(
                    Icons.vpn_key_outlined,
                    color: AppColors.adminPrimary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _submitting ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบแอดมิน',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'เฉพาะเจ้าหน้าที่ที่ได้รับอนุญาตเท่านั้น',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
