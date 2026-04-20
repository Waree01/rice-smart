import 'package:flutter/material.dart';

/// Pest Identification Screen
/// Uses on-device TFLite model (YOLOv5s) for pest detection
class PestIdentificationScreen extends StatelessWidget {
  const PestIdentificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบุศัตรูพืช'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bug_report, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'ถ่ายรูปแมลงเพื่อระบุชนิด',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'AI จะระบุชนิดศัตรูพืชและแนะนำวิธีจัดการ',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement camera capture / gallery pick
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('ถ่ายรูป'),
      ),
    );
  }
}
