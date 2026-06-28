import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/providers/profile_providers.dart';

/// Sign-up / sign-in entry (mockup screen 1).
///
/// A realistic email/phone + password form with a สมัคร ⇄ เข้าสู่ระบบ
/// toggle and field validation. There is no backend yet, so a successful
/// submit just persists the display name and advances to profile setup —
/// swapping in real auth (Firebase) later only touches [_submit]. Social
/// buttons remain as OAuth placeholders.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

enum _AuthMode { signUp, signIn }

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _identityCtrl = TextEditingController(); // email or phone
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _AuthMode _mode = _AuthMode.signUp;
  bool _obscure = true;
  bool _submitting = false;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
    });
  }

  String? _validateIdentity(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'กรุณากรอกอีเมลหรือเบอร์โทร';
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    final isPhone = RegExp(r'^0\d{8,9}$').hasMatch(value);
    if (!isEmail && !isPhone) {
      return 'รูปแบบอีเมลหรือเบอร์โทรไม่ถูกต้อง';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (value.length < 6) return 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    // Simulate a network round-trip so the flow feels real.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // TODO(auth): replace with real Firebase Auth sign-up/sign-in.
    final name = _nameCtrl.text.trim();
    if (_isSignUp && name.isNotEmpty) {
      await ref.read(profileControllerProvider.notifier).update(name: name);
    }
    if (!mounted) return;

    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSignUp ? 'สมัครสมาชิกสำเร็จ' : 'เข้าสู่ระบบสำเร็จ'),
        backgroundColor: AppColors.success,
        duration: const Duration(milliseconds: 1200),
      ),
    );
    context.push('/onboarding/setup');
  }

  void _continueWith(String provider) {
    // TODO(auth): replace with real OAuth once Firebase Auth is wired.
    context.push('/onboarding/setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.spa,
                    size: 40,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ผู้ช่วยชาวนาอัจฉริยะ · วินิจฉัยโรคข้าว · ศัตรูพืช',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], height: 1.4),
                ),
                const SizedBox(height: 24),
                _ModeToggle(mode: _mode, onChanged: _switchMode),
                const SizedBox(height: 20),
                if (_isSignUp) ...[
                  _Field(
                    controller: _nameCtrl,
                    label: 'ชื่อผู้ใช้งาน',
                    hint: 'เช่น ลุงสมชาย ชาวนา',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'กรุณากรอกชื่อผู้ใช้งาน'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                _Field(
                  controller: _identityCtrl,
                  label: 'อีเมล หรือ เบอร์โทร',
                  hint: 'name@email.com หรือ 08xxxxxxxx',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateIdentity,
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _passwordCtrl,
                  label: 'รหัสผ่าน',
                  hint: 'อย่างน้อย 6 ตัวอักษร',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  textInputAction:
                      _isSignUp ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: _isSignUp ? null : (_) => _submit(),
                  validator: _validatePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 14),
                  _Field(
                    controller: _confirmCtrl,
                    label: 'ยืนยันรหัสผ่าน',
                    hint: 'กรอกรหัสผ่านอีกครั้ง',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => v != _passwordCtrl.text
                        ? 'รหัสผ่านไม่ตรงกัน'
                        : null,
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'หรือดำเนินการต่อด้วย',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  background: const Color(0xFF1877F2),
                  foreground: Colors.white,
                  onTap: () => _continueWith('facebook'),
                ),
                const SizedBox(height: 10),
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  background: Colors.white,
                  foreground: const Color(0xFF444441),
                  bordered: true,
                  onTap: () => _continueWith('google'),
                ),
                const SizedBox(height: 22),
                TextButton.icon(
                  onPressed: () => context.push('/admin/login'),
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                    color: AppColors.adminPrimary,
                  ),
                  label: const Text(
                    'เข้าสู่ระบบสำหรับเจ้าหน้าที่ / แอดมิน',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// สมัครสมาชิก ⇄ เข้าสู่ระบบ segmented toggle.
class _ModeToggle extends StatelessWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _segment('สมัครสมาชิก', _AuthMode.signUp),
          _segment('เข้าสู่ระบบ', _AuthMode.signIn),
        ],
      ),
    );
  }

  Widget _segment(String label, _AuthMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryDark : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled text field used across the auth form.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool bordered;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: bordered ? Border.all(color: Colors.grey.shade300) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
