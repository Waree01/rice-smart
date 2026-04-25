import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/weather_forecast.dart';
import '../providers/weather_providers.dart';
import 'location_picker_dialog.dart';

/// Weather screen — 7-day agro-forecast + disease risk + GDD.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to location provider and auto-populate weatherQueryProvider when location is detected.
    // This listener auto-disposes when the widget unmounts, per Riverpod semantics.
    ref.listen(weatherLocationProvider, (prev, next) {
      next.whenData((query) {
        if (query != null) {
          ref.read(weatherQueryProvider.notifier).state = query;
        }
      });
    });

    final async = ref.watch(weatherForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('พยากรณ์อากาศเพื่อการเกษตร'),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'เปลี่ยนตำแหน่ง',
            icon: const Icon(Icons.location_on),
            onPressed: () => showLocationPickerDialog(context),
          ),
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(weatherForecastProvider),
          ),
        ],
      ),
      body: async.when(
        data: (forecast) => forecast == null
            ? _NoLocationState(
                onPicker: () => showLocationPickerDialog(context),
              )
            : _Forecast(forecast: forecast),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(weatherForecastProvider),
        ),
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  final WeatherForecast forecast;
  const _Forecast({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE d MMM', 'th');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(forecast: forecast),
        const SizedBox(height: 16),
        _DiseaseRiskCard(risk: forecast.peakDiseaseRisk),
        const SizedBox(height: 16),
        _GddCard(cumulative: forecast.cumulativeGdd),
        const SizedBox(height: 16),
        Text('พยากรณ์ 7 วัน', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...forecast.daily.map((d) => _DailyTile(day: d, fmt: df)),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'แหล่งข้อมูล: ${_sourceLabel(forecast.source)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push(
            '/chatbot',
            extra:
                'จากพยากรณ์อากาศ 7 วันข้างหน้า ${forecast.summary} ช่วยแนะนำสิ่งที่ควรทำในแปลงนี้ที'
                '${forecast.provinceTh ?? ''} ให้หน่อยครับ',
          ),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('ขอคำแนะนำจากพัสดีตามสภาพอากาศนี้'),
        ),
      ],
    );
  }

  static String _sourceLabel(String source) {
    switch (source) {
      case 'tmd':
        return 'กรมอุตุนิยมวิทยา (TMD)';
      case 'nasa_power':
        return 'NASA POWER (fallback)';
      default:
        return 'ข้อมูลประมาณการ';
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final WeatherForecast forecast;
  const _HeaderCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.info.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.info),
                const SizedBox(width: 6),
                Text(
                  forecast.provinceTh ?? 'ตำแหน่งที่ตั้ง',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              forecast.summary,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiseaseRiskCard extends StatelessWidget {
  final double risk;
  const _DiseaseRiskCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    final pct = (risk * 100).toStringAsFixed(0);
    final Color color;
    final String label;
    if (risk > 0.7) {
      color = AppColors.diseaseCritical;
      label = 'ความเสี่ยงสูง — ควรระวังโรคไหม้และขอบใบแห้ง';
    } else if (risk > 0.4) {
      color = AppColors.warning;
      label = 'ความเสี่ยงปานกลาง — เดินสำรวจแปลงทุกวัน';
    } else {
      color = AppColors.success;
      label = 'ความเสี่ยงต่ำ — ดูแลรักษาตามปกติ';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ดัชนีความเสี่ยงโรค (สัปดาห์นี้)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: risk,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label, style: TextStyle(color: Colors.grey[800])),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GddCard extends StatelessWidget {
  final double cumulative;
  const _GddCard({required this.cumulative});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.eco, color: AppColors.primary, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Growing Degree Days (7 วัน)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${cumulative.toStringAsFixed(1)} GDD',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    'ตัวชี้วัดการสะสมความร้อนช่วงเติบโต ใช้ประเมินระยะข้าว',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

class _DailyTile extends StatelessWidget {
  final DailyForecast day;
  final DateFormat fmt;
  const _DailyTile({required this.day, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final risk = day.diseaseRiskScore;
    final Color riskColor;
    if (risk > 0.7) {
      riskColor = AppColors.diseaseCritical;
    } else if (risk > 0.4) {
      riskColor = AppColors.warning;
    } else {
      riskColor = AppColors.success;
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          day.rainfall > 5 ? Icons.cloudy_snowing : Icons.wb_sunny_outlined,
          color: day.rainfall > 5 ? AppColors.info : AppColors.secondary,
        ),
        title: Text(fmt.format(day.date)),
        subtitle: Text(
          '${day.condition} • ${day.temperature.toStringAsFixed(0)}°C • '
          'RH ${day.humidity.toStringAsFixed(0)}% • '
          'ฝน ${day.rainfall.toStringAsFixed(1)} มม.',
        ),
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'โหลดพยากรณ์อากาศไม่สำเร็จ\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }
}

class _NoLocationState extends StatelessWidget {
  final VoidCallback onPicker;
  const _NoLocationState({required this.onPicker});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่ได้เลือกตำแหน่ง\nโปรดเลือกจังหวัดของคุณ',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPicker,
              child: const Text('เลือกจังหวัด'),
            ),
          ],
        ),
      ),
    );
  }
}
