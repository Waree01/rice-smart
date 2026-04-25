import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/farmer_profile.dart';
import '../providers/profile_providers.dart';

/// Profile setup + edit screen.
///
/// This is the source of truth for Pasadee's personalization context —
/// values entered here flow into the chat system prompt so Pasadee's
/// answers reflect the farmer's location, plot size, and preferred
/// language.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _provinceCtrl;
  late TextEditingController _sizeCtrl;
  String _language = 'th';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider);
    _nameCtrl = TextEditingController(text: profile?.name ?? '');
    _provinceCtrl = TextEditingController(text: profile?.provinceTh ?? '');
    _sizeCtrl = TextEditingController(
        text: profile?.farmSizeRai?.toString() ?? '');
    _language = profile?.language ?? 'th';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _provinceCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final size = double.tryParse(_sizeCtrl.text.trim());
    await ref.read(profileControllerProvider.notifier).update(
          name: _nameCtrl.text.trim(),
          provinceTh: _provinceCtrl.text.trim().isEmpty
              ? null
              : _provinceCtrl.text.trim(),
          farmSizeRai: size,
          language: _language,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยครับ')),
    );
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลชาวนา'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (profile != null)
            IconButton(
              tooltip: 'ล้างข้อมูล',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref.read(profileControllerProvider.notifier).clear();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ล้างข้อมูลแล้ว')));
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(profile: profile),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อที่เรียกคุณ *',
                  hintText: 'เช่น ลุงสมชาย หรือ น้องนก',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _provinceCtrl,
                decoration: const InputDecoration(
                  labelText: 'จังหวัด',
                  hintText: 'เช่น สุโขทัย นครสวรรค์',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ขนาดแปลงนา (ไร่)',
                  hintText: 'เช่น 15',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ภาษาที่ใช้คุย',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                value: 'th',
                groupValue: _language,
                title: const Text('ไทย'),
                onChanged: (v) => setState(() => _language = v ?? 'th'),
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: _language,
                title: const Text('English'),
                onChanged: (v) => setState(() => _language = v ?? 'th'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('บันทึก'),
              ),
              const SizedBox(height: 12),
              Text(
                'ข้อมูลทั้งหมดเก็บในเครื่องของคุณ พัสดีจะใช้เพื่อให้คำแนะนำที่เจาะจงกว่าเดิม ไม่ได้ส่งออกนอก',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FarmerProfile? profile;
  const _Header({this.profile});

  @override
  Widget build(BuildContext context) {
    final isEdit = profile != null;
    return Card(
      color: AppColors.primaryLight.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.agriculture, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'แก้ไขข้อมูลชาวนา' : 'สร้างโปรไฟล์',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'แก้ข้อมูลเพื่อให้พัสดีแนะนำได้ตรงกว่าเดิม'
                        : 'พัสดีจะรู้จักคุณมากขึ้น คำแนะนำจะเจาะจงกว่าเดิม',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
