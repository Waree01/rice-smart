/// One day of agro-weather data.
class DailyForecast {
  final DateTime date;

  /// Air temperature (°C).
  final double temperature;

  /// Relative humidity (%).
  final double humidity;

  /// Accumulated rainfall (mm).
  final double rainfall;

  /// 10m wind speed (m/s).
  final double windSpeed;

  /// Free-text condition label (e.g. "ฝนฟ้าคะนอง").
  final String condition;

  /// Disease pressure in [0.0, 1.0] — from WeatherService scoring.
  final double diseaseRiskScore;

  /// Growing Degree Days for the day, base = 10°C.
  final double gdd;

  const DailyForecast({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.windSpeed,
    required this.condition,
    required this.diseaseRiskScore,
    required this.gdd,
  });
}

/// Seven-day forecast window plus derived agro-indicators.
class WeatherForecast {
  final List<DailyForecast> daily;

  /// Short free-text summary (Thai) for the header card.
  final String summary;

  /// Source of the forecast — 'tmd' or 'nasa_power'.
  final String source;

  /// Location metadata.
  final double latitude;
  final double longitude;
  final String? provinceTh;

  const WeatherForecast({
    required this.daily,
    required this.summary,
    required this.source,
    required this.latitude,
    required this.longitude,
    this.provinceTh,
  });

  /// Max disease risk over the next 7 days — used for the header meter.
  double get peakDiseaseRisk =>
      daily.fold(0.0, (acc, d) => d.diseaseRiskScore > acc ? d.diseaseRiskScore : acc);

  /// Cumulative GDD — crude proxy for crop maturity.
  double get cumulativeGdd => daily.fold(0.0, (acc, d) => acc + d.gdd);
}
