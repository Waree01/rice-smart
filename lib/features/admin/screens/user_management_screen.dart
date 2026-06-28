import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_bottom_nav.dart';

/// User management (mockup screen 10) — view accounts, toggle role and
/// suspension, add a new admin.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  Future<void> _addAdmin(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มแอดมิน'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ชื่อแอดมิน',
            hintText: 'เช่น วิทยา (จนท.)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(userDirectoryServiceProvider).addAdmin(name);
    ref.invalidate(usersProvider);
  }

  Future<void> _editUser(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final svc = ref.read(userDirectoryServiceProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text('${user.roleLabelTh} · ${user.statusLabelTh}'),
            ),
            const Divider(height: 1),
            if (user.role == UserRole.user)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('ตั้งเป็นแอดมิน'),
                onTap: () async {
                  await svc.setRole(user.id, UserRole.admin);
                  ref.invalidate(usersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('ลดเป็นผู้ใช้ทั่วไป'),
                onTap: () async {
                  await svc.setRole(user.id, UserRole.user);
                  ref.invalidate(usersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            if (user.status == UserStatus.active)
              ListTile(
                leading: const Icon(Icons.block, color: AppColors.error),
                title: const Text('ระงับบัญชี'),
                onTap: () async {
                  await svc.setStatus(user.id, UserStatus.suspended);
                  ref.invalidate(usersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              )
            else
              ListTile(
                leading:
                    const Icon(Icons.check_circle, color: AppColors.success),
                title: const Text('คืนสิทธิ์ใช้งาน'),
                onTap: () async {
                  await svc.setStatus(user.id, UserStatus.active);
                  ref.invalidate(usersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('โหลดผู้ใช้ไม่สำเร็จ: $e')),
        data: (list) => Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _UserTile(
                  user: list[i],
                  onTap: () => _editUser(context, ref, list[i]),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _addAdmin(context, ref),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('เพิ่มแอดมิน'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(current: 4),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suspended = user.status == UserStatus.suspended;
    final isAdmin = user.role == UserRole.admin;
    final badgeColor = suspended
        ? AppColors.error
        : isAdmin
            ? AppColors.adminBlue
            : AppColors.primary;
    final badgeText = suspended ? 'ระงับ' : user.roleLabelTh;
    final subtitle = suspended
        ? 'ถูกระงับ'
        : isAdmin && user.labelCount > 0
            ? 'ติดป้าย ${user.labelCount} รูป'
            : (user.provinceTh ?? '—');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: badgeColor.withValues(alpha: 0.15),
        child: Text(
          _initials(user.name),
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      title:
          Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          badgeText,
          style: TextStyle(
            color: badgeColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  static String _initials(String name) {
    final cleaned = name.replaceAll(RegExp(r'\(.*\)'), '').trim();
    if (cleaned.isEmpty) return '?';
    // Thai names have no spaces between given/sur — take first 2 chars.
    return cleaned.length <= 2 ? cleaned : cleaned.substring(0, 2);
  }
}
