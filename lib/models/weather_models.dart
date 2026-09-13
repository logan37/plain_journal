/// A city as returned by Open-Meteo's geocoding API and the location you
/// want weather for.
class CityLocation {
  const CityLocation({
    required this.id,
    required this.name,
    required this.country,
    this.region,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String country;
  final String? region;
  final double latitude;
  final double longitude;

  String get displayName {
    final parts = <String>[name];
    if (region != null && region!.isNotEmpty) parts.add(region!);
    parts.add(country);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'region': region,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory CityLocation.fromJson(Map<String, dynamic> json) => CityLocation(
        id: json['id'] as int,
        name: json['name'] as String,
        country: json['country'] as String,
        region: json['region'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}

/// Parsed forecast for a single day.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.code,
    required this.tempMax,
    required this.tempMin,
    this.precipitationProbability,
  });

  final DateTime date;
  final int code;
  final double tempMax;
  final double tempMin;
  final int? precipitationProbability;

  WeatherCode get weather => weatherCodeFrom(code);

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'code': code,
        'tempMax': tempMax,
        'tempMin': tempMin,
        'precipitationProbability': precipitationProbability,
      };

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date'] as String),
        code: json['code'] as int,
        tempMax: (json['tempMax'] as num).toDouble(),
        tempMin: (json['tempMin'] as num).toDouble(),
        precipitationProbability: json['precipitationProbability'] as int?,
      );
}

/// Real-time conditions fetched alongside the daily forecast.
class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.code,
  });

  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final int code;

  WeatherCode get weather => weatherCodeFrom(code);
}

/// Everything needed to render the weather screen.
class WeatherBundle {
  const WeatherBundle({
    required this.city,
    required this.current,
    required this.daily,
  });

  final CityLocation city;
  final CurrentWeather current;
  final List<DailyForecast> daily;
}

/// WMO weather interpretation codes from Open-Meteo.
enum WeatherCode {
  clear(0, 'Clear sky', '☀️'),
  mostlyClear(1, 'Mainly clear', '🌤️'),
  partlyCloudy(2, 'Partly cloudy', '⛅'),
  overcast(3, 'Overcast', '☁️'),
  fog(45, 'Fog', '🌫️'),
  lightDrizzle(51, 'Light drizzle', '🌦️'),
  drizzle(53, 'Drizzle', '🌦️'),
  heavyDrizzle(55, 'Heavy drizzle', '🌧️'),
  lightRain(61, 'Light rain', '🌦️'),
  rain(63, 'Rain', '🌧️'),
  heavyRain(65, 'Heavy rain', '🌧️'),
  freezingDrizzle(66, 'Freezing drizzle', '🌧️'),
  freezingRain(67, 'Freezing rain', '🌧️'),
  lightSnow(71, 'Light snow', '🌨️'),
  snow(73, 'Snow', '❄️'),
  heavySnow(75, 'Heavy snow', '❄️'),
  rainShowers(80, 'Rain showers', '🌦️'),
  heavyRainShowers(81, 'Rain showers', '🌧️'),
  violentRainShowers(82, 'Violent showers', '⛈️'),
  snowShowers(85, 'Snow showers', '🌨️'),
  heavySnowShowers(86, 'Heavy snow showers', '❄️'),
  thunderstorm(95, 'Thunderstorm', '⛈️'),
  thunderstormHailLight(96, 'Thunderstorm, hail', '⛈️'),
  thunderstormHailHeavy(99, 'Thunderstorm, heavy hail', '⛈️'),
  unknown(-1, 'Unknown', '🌡️');

  const WeatherCode(this.code, this.label, this.icon);

  final int code;
  final String label;
  final String icon;

  static WeatherCode fromCode(int code) {
    for (final w in WeatherCode.values) {
      if (w.code == code) return w;
    }
    return unknown;
  }
}

WeatherCode weatherCodeFrom(int code) => WeatherCode.fromCode(code);