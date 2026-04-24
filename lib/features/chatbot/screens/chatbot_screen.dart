import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/llm_gateway.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/chatbot_providers.dart';
import '../widgets/chat_bubble.dart';

/// Pasadee Chatbot Screen.
///
/// Lives on top of the multi-LLM [LlmGateway]: chooses a preferred
/// provider, streams (well, polls) the response, and renders markdown
/// replies. Supports a pre-seeded prompt via `GoRouterState.extra` so
/// the disease/pest detection screens can hand a diagnosis over to
/// Pasadee for follow-up.
class ChatbotScreen extends ConsumerStatefulWidget {
  /// Optional prompt to auto-send on first build (used when navigating
  /// from disease/pest screens).
  final String? initialPrompt;
  const ChatbotScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _didSeed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSeed && widget.initialPrompt != null) {
      _didSeed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatbotControllerProvider.notifier).send(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(chatbotControllerProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatbotControllerProvider);
    final preferred = ref.watch(preferredLlmProvider);

    ref.listen(chatbotControllerProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Text('พ',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('พัสดี',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('ผู้ช่วยชาวนาอัจฉริยะ',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            _ProviderPill(selected: preferred),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ล้างประวัติ',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () =>
                ref.read(chatbotControllerProvider.notifier).clear(),
          ),
          IconButton(
            tooltip: 'เปลี่ยนผู้ช่วย',
            icon: const Icon(Icons.tune),
            onPressed: () => _showProviderSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return const _SuggestedPrompts();
                  return ChatBubble(message: messages[index - 1]);
                },
              ),
            ),
            _InputBar(
              controller: _input,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProviderSheet(BuildContext context) async {
    final selected = ref.read(preferredLlmProvider);
    final providers = LlmGateway.providers;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Row(
                children: [
                  Icon(Icons.psychology_outlined),
                  SizedBox(width: 8),
                  Text('เลือกผู้ช่วยของพัสดี',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'พัสดีใช้ LLM แต่ละตัวต่างกัน เพื่อเปรียบเทียบคุณภาพคำตอบ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(),
            ...providers.map((p) => RadioListTile<String>(
                  value: p.id,
                  groupValue: selected,
                  title: Text(p.displayName),
                  subtitle: Text(p.model),
                  onChanged: (v) => Navigator.of(ctx).pop(v),
                )),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(preferredLlmProvider.notifier).state = picked;
    }
  }
}

class _ProviderPill extends StatelessWidget {
  final String selected;
  const _ProviderPill({required this.selected});

  @override
  Widget build(BuildContext context) {
    final display = LlmGateway.providers
        .firstWhere((p) => p.id == selected,
            orElse: () => LlmGateway.providers.first)
        .displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        display,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'ถามพัสดีได้เลยครับ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedPrompts extends ConsumerWidget {
  const _SuggestedPrompts();

  static const _prompts = [
    'ข้าวพันธุ์ไหนเหมาะกับภาคกลางในช่วงฝนแล้ง',
    'ฝนตกหนักติดต่อกัน 3 วัน ควรดูแลนาอย่างไร',
    'ลดต้นทุนปุ๋ยเคมีได้อย่างไรบ้าง',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('คำถามยอดนิยม',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _prompts)
                ActionChip(
                  label: Text(p),
                  onPressed: () =>
                      ref.read(chatbotControllerProvider.notifier).send(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
