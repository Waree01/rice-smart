import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/disease_result.dart';
import 'cloud_second_opinion.dart';

/// Result card shown after a successful disease inference.
class DiseaseResultCard extends StatelessWidget {
  final DiseaseResult result;
  final VoidCallback onRetry;
  final VoidCallback onAskPasadee;

  const DiseaseResultCard({
    super.key,
    required this.result,
    required this.onRetry,
    required this.onAskPasadee,
  });

  @override
  Widget build(BuildContext context) {
    final confidencePct = (result.confidence * 100).toStringAsFixed(1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(result.imagePath!),
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, size: 56),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: result.severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.severityLabelTh,
                        style: TextStyle(
                          color: result.severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text('ความมั่นใจ $confidencePct%'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.diseaseName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    result.diseaseNameEn,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.recommendation,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  if (result.details != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      result.details!,
                      style: TextStyle(color: Colors.grey[800], height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (result.imagePath != null &&
              result.confidence < 0.75) ...[
            const SizedBox(height: 16),
            CloudSecondOpinion(imagePath: result.imagePath!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ถ่ายใหม่'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAskPasadee,
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('ถามพัสดี'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
