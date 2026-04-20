import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

/// Main dashboard - entry point of the app
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('${AppConstants.appName} - ${AppConstants.chatbotNameThai}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome card
            Card(
              color: AppColors.primaryLight.withOpacity(0.1),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'สวัสดีครับ! ผมพัสดี',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ผู้ช่วยชาวนาอัจฉริยะ พร้อมดูแลนาข้าวของคุณ',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Feature cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _FeatureCard(
                    icon: Icons.local_florist,
                    title: 'วินิจฉัยโรคข้าว',
                    subtitle: 'ถ่ายรูปใบข้าว AI วิเคราะห์',
                    color: AppColors.error,
                    onTap: () => context.push('/disease-detection'),
                  ),
                  _FeatureCard(
                    icon: Icons.bug_report,
                    title: 'ระบุศัตรูพืช',
                    subtitle: 'ถ่ายรูปแมลง AI ระบุชนิด',
                    color: AppColors.warning,
                    onTap: () => context.push('/pest-identification'),
                  ),
                  _FeatureCard(
                    icon: Icons.chat,
                    title: 'คุยกับพัสดี',
                    subtitle: 'ถามเรื่องปลูกข้าวได้เลย',
                    color: AppColors.primary,
                    onTap: () => context.push('/chatbot'),
                  ),
                  _FeatureCard(
                    icon: Icons.cloud,
                    title: 'พยากรณ์อากาศ',
                    subtitle: 'สภาพอากาศและคำแนะนำ',
                    color: AppColors.info,
                    onTap: () {
                      // TODO: Navigate to weather screen
                    },
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
