import 'package:flutter/material.dart';

/// Rice Disease Detection Screen
/// Uses on-device TFLite model (EfficientNet-B0) for CNN inference
class DiseaseDetectionScreen extends StatelessWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('วินิจฉัยโรคข้าว'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_florist, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'ถ่ายรูปใบข้าวเพื่อวินิจฉัยโรค',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'AI จะวิเคราะห์โรคจากภาพถ่าย',
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
