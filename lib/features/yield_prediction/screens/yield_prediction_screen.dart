import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/providers/profile_providers.dart';
import '../services/yield_prediction_service.dart';

/// Yield prediction screen. Inputs are deliberately simple so a
/// non-technical farmer can use it; defaults come from the profile.
class YieldPredictionScreen extends ConsumerStatefulWidget {
  const YieldPredictionScreen({super.key});

  @override
  ConsumerState<YieldPredictionScreen> createState() =>
      _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends ConsumerState<YieldPredictionScreen> {
  final _service = YieldPredictionService();

  double _daysSince = 60;
  double _cumulativeGdd = 1500;
  double _rainfallMm = 800;
  double _diseaseCount = 0;
  double _pestCount = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    final size = profile?.farmSizeRai ?? 10;

    final current = _service.predict(
      cumulativeGdd: _cumulativeGdd,
      daysSinceTransplant: _daysSince.toInt(),
      diseaseIncidents: _diseaseCount.toInt(),
      pestIncidents: _pestCount.toInt(),
      rainfallMm: _rainfallMm,
      farmSizeRai: size,
    );

    final projection = _service.projection(
      cumulativeGdd: _cumulativeGdd,
      daysSinceTransplant: _daysSince.toInt(),
      diseaseIncidents: _diseaseCount.toInt(),
      pestIncidents: _pestCount.toInt(),
      rainfallMm: _rainfallMm,
      farmSizeRai: size,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประมาณการผลผลิต'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeadlineCard(prediction: current, farmSizeRai: size),
          const SizedBox(height: 16),
          _FactorsCard(factors: current.factors),
          const SizedBox(height: 16),
          _ProjectionChart(projection: projection),
          const SizedBox(height: 16),
          _InputsCard(
            daysSince: _daysSince,
            cumulativeGdd: _cumulativeGdd,
            rainfallMm: _rainfallMm,
            diseaseCount: _diseaseCount,
            pestCount: _pestCount,
            onDays: (v) => setState(() => _daysSince = v),
            onGdd: (v) => setState(() => _cumulativeGdd = v),
            onRain: (v) => setState(() => _rainfallMm = v),
            onDisease: (v) => setState(() => _diseaseCount = v),
            onPest: (v) => setState(() => _pestCount = v),
          ),
          const SizedBox(height: 12),
          Text(
            'โมเดลนี้เป็น regression baseline ที่ใช้ค่าสัมประสิทธิ์จากวรรณกรรมวิจัยข้าวไทย ยังไม่ผ่านการ fine-tune บนข้อมูลแปลงจริง — ใช้เป็นแนวทางอ้างอิงเท่านั้นครับ',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final YieldPrediction prediction;
  final double farmSizeRai;
  const _HeadlineCard({required this.prediction, required this.farmSizeRai});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondaryLight.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prediction.stageTh,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${prediction.tonnesPerRai.toStringAsFixed(2)} ตัน/ไร่',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'รวม ${prediction.totalTonnes.toStringAsFixed(2)} ตัน สำหรับพื้นที่ ${farmSizeRai.toStringAsFixed(1)} ไร่',
              style: TextStyle(color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: prediction.confidence,
              color: AppColors.primary,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text(
              'ความเชื่อมั่นของโมเดล ${(prediction.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactorsCard extends StatelessWidget {
  final YieldFactors factors;
  const _FactorsCard({required this.factors});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ปัจจัยที่ส่งผล',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _factorBar('ความร้อนสะสม (GDD)', factors.gdd),
            _factorBar('ปลอดจากโรค', factors.disease),
            _factorBar('ปลอดจากศัตรูพืช', factors.pest),
            _factorBar('ปริมาณฝน', factors.rainfall),
          ],
        ),
      ),
    );
  }

  Widget _factorBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              color: value > 0.8
                  ? AppColors.success
                  : value > 0.5
                      ? AppColors.warning
                      : AppColors.error,
              backgroundColor: Colors.grey.shade200,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          Text('${(value * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

class _ProjectionChart extends StatelessWidget {
  final List<YieldPrediction> projection;
  const _ProjectionChart({required this.projection});

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < projection.length; i++)
        FlSpot(i.toDouble(), projection[i].tonnesPerRai),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แนวโน้มผลผลิตที่คาดการณ์ (6 สัปดาห์ข้างหน้า)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 0.4,
                        getTitlesWidget: (v, _) => Text(
                          v.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, _) => Text(
                          '+${v.toInt()}w',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputsCard extends StatelessWidget {
  final double daysSince;
  final double cumulativeGdd;
  final double rainfallMm;
  final double diseaseCount;
  final double pestCount;
  final ValueChanged<double> onDays;
  final ValueChanged<double> onGdd;
  final ValueChanged<double> onRain;
  final ValueChanged<double> onDisease;
  final ValueChanged<double> onPest;

  const _InputsCard({
    required this.daysSince,
    required this.cumulativeGdd,
    required this.rainfallMm,
    required this.diseaseCount,
    required this.pestCount,
    required this.onDays,
    required this.onGdd,
    required this.onRain,
    required this.onDisease,
    required this.onPest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ปรับข้อมูลแปลงนา',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _slider(
              'อายุหลังปักดำ (วัน)',
              daysSince,
              0,
              130,
              (v) => v.toStringAsFixed(0),
              onDays,
            ),
            _slider(
              'GDD สะสม (°C·day)',
              cumulativeGdd,
              0,
              3500,
              (v) => v.toStringAsFixed(0),
              onGdd,
            ),
            _slider(
              'ปริมาณฝนสะสม (มม.)',
              rainfallMm,
              0,
              3000,
              (v) => v.toStringAsFixed(0),
              onRain,
            ),
            _slider(
              'จำนวนครั้งที่พบโรค',
              diseaseCount,
              0,
              12,
              (v) => v.toStringAsFixed(0),
              onDisease,
            ),
            _slider(
              'จำนวนครั้งที่พบศัตรูพืช',
              pestCount,
              0,
              12,
              (v) => v.toStringAsFixed(0),
              onPest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    String Function(double) fmt,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(fmt(value), style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
