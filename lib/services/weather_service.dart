import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_models.dart';

/// Thin client for the Open-Meteo geocoding + forecast APIs.
///
/// No API key required.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _geoBase = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastBase = 'https://api.open-meteo.com/v1/forecast';

  /// Searches for cities matching [query].
  Future<List<CityLocation>> searchCities(String query, {int limit = 8}) async {
    final uri = Uri.parse(_geoBase).replace(queryParameters: {
      'name': query,
      'count': '$limit',
      'language': 'en',
      'format': 'json',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Geocoding failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? const [];

    return results.map<CityLocation>((raw) {
      final json = raw as Map<String, dynamic>;
      return CityLocation(
        id: json['id'] as int,
        name: json['name'] as String,
        country: json['country'] as String? ?? '',
        region: json['admin1'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
    }).toList();
  }

  /// Fetches current conditions + a 7-day forecast for [city].
  Future<WeatherBundle> fetchForecast(CityLocation city) async {
    final uri = Uri.parse(_forecastBase).replace(queryParameters: {
      'latitude': '${city.latitude}',
      'longitude': '${city.longitude}',
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Forecast failed (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final currentJson = json['current'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;

    final current = CurrentWeather(
      temperature: (currentJson['temperature_2m'] as num).toDouble(),
      apparentTemperature:
          (currentJson['apparent_temperature'] as num).toDouble(),
      humidity: currentJson['relative_humidity_2m'] as int,
      windSpeed: (currentJson['wind_speed_10m'] as num).toDouble(),
      code: currentJson['weather_code'] as int,
    );

    final dates = (dailyJson['time'] as List).cast<String>();
    final codes = (dailyJson['weather_code'] as List).cast<int>();
    final tempMax = (dailyJson['temperature_2m_max'] as List).cast<num>();
    final tempMin = (dailyJson['temperature_2m_min'] as List).cast<num>();
    final precip =
        (dailyJson['precipitation_probability_max'] as List?)?.cast<num>();

    final daily = <DailyForecast>[];
    for (var i = 0; i < dates.length; i++) {
      daily.add(DailyForecast(
        date: DateTime.parse(dates[i]),
        code: codes[i],
        tempMax: tempMax[i].toDouble(),
        tempMin: tempMin[i].toDouble(),
        precipitationProbability: precip != null && i < precip.length
            ? precip[i].toInt()
            : null,
      ));
    }

    return WeatherBundle(city: city, current: current, daily: daily);
  }
}