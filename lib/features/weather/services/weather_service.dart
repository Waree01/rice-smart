import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/weather_forecast.dart';

/// Weather service for agro-weather data.
///
/// Primary source: Thai Meteorological Department (TMD). Falls back to
/// NASA POWER satellite data when TMD is unreachable or the TMD token
/// is missing. The service always returns a [WeatherForecast] with
/// derived agro-indicators (disease risk, GDD) so the UI doesn't need
/// provider-specific knowledge.
class WeatherService {
  final Dio _dio;
  final Logger _logger;

  WeatherService({Dio? dio, Logger? logger})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            )),
        _logger = logger ?? Logger();

  /// Load a 7-day agro-weather forecast for ([lat], [lon]).
  Future<WeatherForecast> fetchForecast({
    required double lat,
    required double lon,
    String? tmdApiKey,
    String? provinceTh,
  }) async {
    if (tmdApiKey != null && tmdApiKey.isNotEmpty) {
      try {
        final raw = await _fetchTmd(lat: lat, lon: lon, apiKey: tmdApiKey);
        return _buildForecast(
          raw: raw,
          source: 'tmd',
          lat: lat,
          lon: lon,
          provinceTh: provinceTh,
        );
      } catch (e) {
        _logger.w('TMD failed, trying NASA POWER', error: e);
      }
    }
    try {
      final raw = await _fetchNasaPower(lat: lat, lon: lon);
      return _buildForecast(
        raw: raw,
        source: 'nasa_power',
        lat: lat,
        lon: lon,
        provinceTh: provinceTh,
      );
    } catch (e) {
      _logger.e('All weather sources failed — returning synthetic week',
          error: e);
      return _buildForecast(
        raw: const {},
        source: 'synthetic',
        lat: lat,
        lon: lon,
        provinceTh: provinceTh,
      );
    }
  }

  // ── TMD ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchTmd({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '${AppConstants.tmdBaseUrl}/forecast/location/daily/at',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'fields': 'tc,rh,rain,ws10m,cond',
        'duration': 7,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      }),
    );
    return resp.data ?? const {};
  }

  // ── NASA POWER (fallback) ─────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchNasaPower({
    required double lat,
    required double lon,
  }) async {
    final start = DateTime.now();
    final end = start.add(const Duration(days: 6));
    final resp = await _dio.get<Map<String, dynamic>>(
      AppConstants.nasaPowerUrl,
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'community': 'AG',
        'parameters': 'T2M,RH2M,PRECTOTCORR,WS2M',
        'format': 'JSON',
        'start': _formatDate(start),
        'end': _formatDate(end),
      },
    );
    return resp.data ?? const {};
  }

  WeatherForecast _buildForecast({
    required Map<String, dynamic> raw,
    required String source,
    required double lat,
    required double lon,
    String? provinceTh,
  }) {
    final days = switch (source) {
      'tmd' => _normalizeTmd(raw),
      'nasa_power' => _normalizeNasaPower(raw),
      _ => _syntheticWeek(),
    };

    final daily = days.map((d) {
      final risk = calculateDiseaseRiskScore(
        temperature: d.temperature,
        humidity: d.humidity,
        rainfall: d.rainfall,
      );
      final gdd = calculateGDD(
        maxTemp: d.temperature + 4,
        minTemp: d.temperature - 4,
      );
      return DailyForecast(
        date: d.date,
        temperature: d.temperature,
        humidity: d.humidity,
        rainfall: d.rainfall,
        windSpeed: d.windSpeed,
        condition: d.condition,
        diseaseRiskScore: risk,
        gdd: gdd,
      );
    }).toList();

    final summary = _composeSummary(daily);
    return WeatherForecast(
      daily: daily,
      summary: summary,
      source: source,
      latitude: lat,
      longitude: lon,
      provinceTh: provinceTh,
    );
  }

  String _composeSummary(List<DailyForecast> days) {
    if (days.isEmpty) return 'ไม่มีข้อมูลพยากรณ์ในขณะนี้';
    final tomorrow = days.first;
    final risk = tomorrow.diseaseRiskScore;
    final riskTxt = risk > 0.7
        ? 'ความเสี่ยงโรคสูง'
        : risk > 0.4
            ? 'ความเสี่ยงโรคปานกลาง'
            : 'ความเสี่ยงโรคต่ำ';
    return 'พรุ่งนี้ ${tomorrow.condition} อุณหภูมิ ${tomorrow.temperature.toStringAsFixed(1)}°C '
        'ความชื้น ${tomorrow.humidity.toStringAsFixed(0)}%, $riskTxt';
  }

  // ── Agro-weather helpers (also used by unit tests) ────────────────

  /// Disease pressure score in [0.0, 1.0].
  /// Warm + humid + wet conditions push the score higher.
  double calculateDiseaseRiskScore({
    required double temperature,
    required double humidity,
    required double rainfall,
  }) {
    double risk = 0.0;
    if (temperature >= 25 && temperature <= 28) risk += 0.3;
    if (humidity > 85) risk += 0.4;
    if (rainfall > 10) risk += 0.3;
    return risk.clamp(0.0, 1.0);
  }

  /// Growing Degree Days (GDD), base 10°C by default.
  double calculateGDD({
    required double maxTemp,
    required double minTemp,
    double baseTemp = 10.0,
  }) {
    final avg = (maxTemp + minTemp) / 2;
    return (avg - baseTemp).clamp(0.0, double.infinity);
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  // ── Provider-specific normalization ───────────────────────────────
  List<_RawDay> _normalizeTmd(Map<String, dynamic> raw) {
    final list = raw['WeatherForecasts'];
    if (list is! List || list.isEmpty) return _syntheticWeek();
    final forecasts = (list.first as Map<String, dynamic>?)?['forecasts'];
    if (forecasts is! List) return _syntheticWeek();
    final out = <_RawDay>[];
    for (final entry in forecasts.take(7)) {
      if (entry is! Map<String, dynamic>) continue;
      final date = DateTime.tryParse(entry['time']?.toString() ?? '') ??
          DateTime.now();
      final data = (entry['data'] as Map?) ?? const {};
      out.add(_RawDay(
        date: date,
        temperature: (data['tc'] as num?)?.toDouble() ?? 28.0,
        humidity: (data['rh'] as num?)?.toDouble() ?? 80.0,
        rainfall: (data['rain'] as num?)?.toDouble() ?? 0.0,
        windSpeed: (data['ws10m'] as num?)?.toDouble() ?? 2.0,
        condition: _tmdCondition(data['cond']),
      ));
    }
    return out.isEmpty ? _syntheticWeek() : out;
  }

  List<_RawDay> _normalizeNasaPower(Map<String, dynamic> raw) {
    final props = ((raw['properties'] as Map?)?['parameter']) as Map?;
    if (props == null) return _syntheticWeek();
    final t = (props['T2M'] as Map?)?.cast<String, num>() ?? {};
    final rh = (props['RH2M'] as Map?)?.cast<String, num>() ?? {};
    final rain = (props['PRECTOTCORR'] as Map?)?.cast<String, num>() ?? {};
    final wind = (props['WS2M'] as Map?)?.cast<String, num>() ?? {};
    final keys = t.keys.toList()..sort();
    final out = <_RawDay>[];
    for (final k in keys.take(7)) {
      if (k.length < 8) continue;
      final y = int.tryParse(k.substring(0, 4)) ?? DateTime.now().year;
      final m = int.tryParse(k.substring(4, 6)) ?? DateTime.now().month;
      final d = int.tryParse(k.substring(6, 8)) ?? DateTime.now().day;
      out.add(_RawDay(
        date: DateTime(y, m, d),
        temperature: t[k]?.toDouble() ?? 28.0,
        humidity: rh[k]?.toDouble() ?? 80.0,
        rainfall: rain[k]?.toDouble() ?? 0.0,
        windSpeed: wind[k]?.toDouble() ?? 2.0,
        condition: 'ปกติ',
      ));
    }
    return out.isEmpty ? _syntheticWeek() : out;
  }

  /// Fallback when remote APIs return no usable data — still lets the
  /// UI render something instead of a crash screen.
  List<_RawDay> _syntheticWeek() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      return _RawDay(
        date: now.add(Duration(days: i)),
        temperature: 29 + (i % 3),
        humidity: 78 + ((i * 2) % 12),
        rainfall: (i == 2 || i == 5) ? 8.0 : 1.0,
        windSpeed: 2.2,
        condition: (i == 2 || i == 5) ? 'ฝนเป็นบางแห่ง' : 'ท้องฟ้าโปร่ง',
      );
    });
  }

  String _tmdCondition(Object? code) {
    if (code is! int) return 'ปกติ';
    const map = {
      1: 'ท้องฟ้าโปร่ง',
      2: 'มีเมฆบางส่วน',
      3: 'เมฆเป็นส่วนมาก',
      4: 'มีเมฆมาก',
      5: 'ฝนตกเล็กน้อย',
      6: 'ฝนปานกลาง',
      7: 'ฝนตกหนัก',
      8: 'ฝนฟ้าคะนอง',
      9: 'อากาศหนาวจัด',
    };
    return map[code] ?? 'ปกติ';
  }
}

class _RawDay {
  final DateTime date;
  final double temperature;
  final double humidity;
  final double rainfall;
  final double windSpeed;
  final String condition;
  const _RawDay({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
  });
}
