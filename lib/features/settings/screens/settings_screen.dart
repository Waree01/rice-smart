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

/// Settings screen — LLM preference, RAG backend, profile link, about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = ref.watch(preferredLlmProvider);
    final embedding = ref.watch(embeddingBackendProvider);
    final ragReady = ref.watch(ragReadyProvider);

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
          const _SectionHeader(title: 'ผู้ช่วยของพัสดี (LLM)'),
          for (final p in LlmGateway.providers)
            RadioListTile<String>(
              value: p.id,
              groupValue: preferred,
              title: Text(p.displayName),
              subtitle: Text(p.model),
              onChanged: (v) {
                if (v != null) {
                  ref.read(preferredLlmProvider.notifier).state = v;
                }
              },
            ),
          const Divider(),
          const _SectionHeader(title: 'RAG Embedding Backend'),
          ListTile(
            leading: Icon(ragReady
                ? Icons.check_circle
                : Icons.pending_outlined),
            title: Text(ragReady
                ? 'RAG index พร้อมใช้'
                : 'RAG ยังไม่พร้อม (ตรวจ API key)'),
            subtitle: const Text('เปลี่ยน backend เพื่องานวิจัยเปรียบเทียบ'),
          ),
          RadioListTile<EmbeddingBackend>(
            value: EmbeddingBackend.wangchanberta,
            groupValue: embedding,
            title: const Text('WangchanBERTa (Thai-native)'),
            subtitle: const Text('ผ่าน HuggingFace Inference API'),
            onChanged: (v) {
              if (v != null) {
                ref.read(embeddingBackendProvider.notifier).state = v;
              }
            },
          ),
          RadioListTile<EmbeddingBackend>(
            value: EmbeddingBackend.openai,
            groupValue: embedding,
            title: const Text('OpenAI text-embedding-3-small'),
            subtitle: const Text('Multilingual baseline'),
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
                  'https://github.com/nenoteerawat/rice-smart/blob/main/SECURITY.md'),
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
            leading: const Icon(Icons.restart_alt, color: Colors.red),
            title: const Text('ล้างการตั้งค่าและ onboarding'),
            subtitle:
                const Text('แอปจะแสดง onboarding อีกครั้งในครั้งถัดไป'),
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
