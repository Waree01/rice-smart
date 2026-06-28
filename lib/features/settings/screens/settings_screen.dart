import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/embedding_service.dart';
import '../../../core/services/llm_gateway.dart';
import '../../../core/theme/app_colors.dart';
import '../../chatbot/providers/chatbot_providers.dart';
import '../../profile/providers/profile_providers.dart';

/// Settings screen — LLM preference, RAG backend, profile link, about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = ref.watch(preferredLlmProvider);
    final embedding = ref.watch(embeddingBackendProvider);
    final ragReady = ref.watch(ragReadyProvider);
    final profile = ref.watch(profileControllerProvider);
    final isAdmin = profile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่า'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'โปรไฟล์'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('ข้อมูลชาวนา'),
            subtitle:
                const Text('ชื่อ จังหวัด ขนาดแปลง — ใช้ปรับบริบทของพัสดี'),
            onTap: () => context.push('/profile'),
          ),
          const Divider(),
          const _SectionHeader(title: 'เจ้าหน้าที่ / แอดมิน'),
          if (!isAdmin)
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.adminPrimary,
              ),
              title: const Text('เข้าสู่ระบบแอดมิน'),
              subtitle:
                  const Text('ต้องใช้รหัสแอดมินเพื่อเปิดสิทธิ์ควบคุมคุณภาพ'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/login'),
            ),
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(
                Icons.dashboard_customize_outlined,
                color: AppColors.adminPrimary,
              ),
              title: const Text('เปิดแดชบอร์ดแอดมิน'),
              subtitle:
                  const Text('คิวตรวจสอบ · ติดป้าย · แผนที่ระบาด · ผู้ใช้'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin'),
            ),
            ListTile(
              leading: const Icon(Icons.logout_outlined, color: Colors.red),
              title: const Text('ออกจากโหมดแอดมิน'),
              subtitle: const Text('กลับไปเป็นผู้ใช้ทั่วไป'),
              onTap: () => ref
                  .read(profileControllerProvider.notifier)
                  .update(role: 'user'),
            ),
          ],
          const Divider(),
          const _SectionHeader(title: 'ผู้ช่วยของพัสดี (LLM)'),
          for (final p in LlmGateway.providers)
            RadioListTile<String>(
              value: p.id,
              // ignore: deprecated_member_use
              groupValue: preferred,
              title: Text(p.displayName),
              subtitle: Text(p.model),
              // ignore: deprecated_member_use
              onChanged: (v) {
                if (v != null) {
                  ref.read(preferredLlmProvider.notifier).state = v;
                }
              },
            ),
          const Divider(),
          const _SectionHeader(title: 'RAG Embedding Backend'),
          ListTile(
            leading:
                Icon(ragReady ? Icons.check_circle : Icons.pending_outlined),
            title: Text(
              ragReady
                  ? 'RAG index พร้อมใช้'
                  : 'RAG ยังไม่พร้อม (ตรวจ API key)',
            ),
            subtitle: const Text('เปลี่ยน backend เพื่องานวิจัยเปรียบเทียบ'),
          ),
          RadioListTile<EmbeddingBackend>(
            value: EmbeddingBackend.wangchanberta,
            // ignore: deprecated_member_use
            groupValue: embedding,
            title: const Text('WangchanBERTa (Thai-native)'),
            subtitle: const Text('ผ่าน HuggingFace Inference API'),
            // ignore: deprecated_member_use
            onChanged: (v) {
              if (v != null) {
                ref.read(embeddingBackendProvider.notifier).state = v;
              }
            },
          ),
          RadioListTile<EmbeddingBackend>(
            value: EmbeddingBackend.openai,
            // ignore: deprecated_member_use
            groupValue: embedding,
            title: const Text('OpenAI text-embedding-3-small'),
            subtitle: const Text('Multilingual baseline'),
            // ignore: deprecated_member_use
            onChanged: (v) {
              if (v != null) {
                ref.read(embeddingBackendProvider.notifier).state = v;
              }
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'การวิจัย'),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('LLM Benchmark'),
            subtitle: const Text('วัดคุณภาพ/ความเร็วของแต่ละ provider'),
            onTap: () => context.push('/benchmark'),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('รายงานในชุมชน'),
            subtitle: const Text('ดูข้อมูลเฝ้าระวังการระบาด'),
            onTap: () => context.push('/community'),
          ),
          const Divider(),
          const _SectionHeader(title: 'เกี่ยวกับ'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text(AppConstants.appName),
            subtitle: Text('เวอร์ชัน 0.2.0 — โครงการปริญญานิพนธ์'),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('นโยบายความปลอดภัย'),
            subtitle: const Text('SECURITY.md'),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/nenoteerawat/rice-smart/blob/main/SECURITY.md',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('ซอร์สโค้ด'),
            subtitle: const Text('github.com/nenoteerawat/rice-smart'),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/nenoteerawat/rice-smart'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'ข้อมูลผู้ใช้'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ออกจากระบบ / กลับหน้าสมัคร'),
            subtitle:
                const Text('ล้างโปรไฟล์และ onboarding แล้วไปหน้าสมัครทันที'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('ออกจากระบบ?'),
                  content: const Text(
                    'จะล้างชื่อผู้ใช้และข้อมูลโปรไฟล์ในเครื่อง '
                    'แล้วกลับไปหน้าสมัครสมาชิก',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('ยกเลิก'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('ออกจากระบบ'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await ref.read(profileControllerProvider.notifier).clear();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.onboardingKey);
              if (!context.mounted) return;
              context.go('/onboarding');
            },
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.red),
            title: const Text('ล้างเฉพาะ onboarding'),
            subtitle: const Text('แอปจะแสดงหน้าสมัครอีกครั้งในการเปิดถัดไป'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.onboardingKey);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ล้างการตั้งค่าแล้ว')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
