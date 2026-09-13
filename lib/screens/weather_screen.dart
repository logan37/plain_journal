import 'dart:async';

import 'package:flutter/material.dart';

import '../models/weather_models.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';

/// Weather tab: search for a city (Open-Meteo geocoding), then show
/// current conditions + a 7-day forecast for it.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.app});

  final AppState app;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<CityLocation> _results = [];
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(trimmed));
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await widget.app.weatherService.searchCities(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search for a city…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: app,
              builder: (context, _) {
                if (_searchError != null) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        _searchError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  );
                }
                if (_results.isNotEmpty) {
                  return ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final city = _results[index];
                      final isSelected =
                          app.city?.id == city.id &&
                              app.city?.latitude == city.latitude &&
                              app.city?.longitude == city.longitude;
                      return _CityTile(
                        city: city,
                        selected: isSelected,
                        onTap: () async {
                          await app.setCity(city);
                        },
                      );
                    },
                  );
                }
                return _ForecastView(app: app);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final CityLocation city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.location_city,
          color: selected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(city.name),
      subtitle: Text(city.displayName),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

/// Fetches the stored city's forecast and renders it.
class _ForecastView extends StatelessWidget {
  const _ForecastView({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = app.city;
    final weather = app.weather;
    final error = app.weatherError;

    if (city == null) {
      return _CenterHint(
        icon: Icons.location_searching,
        text: 'Search for a city to see its weather.',
      );
    }

    if (error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(error, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: app.refreshWeather,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final current = weather.current;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(current.weather.icon, style: const TextStyle(fontSize: 56)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${current.temperature.round()}°C',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        current.weather.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherStat(
                  icon: Icons.thermostat,
                  value: '${current.apparentTemperature.round()}°',
                  label: 'Feels like',
                ),
                _WeatherStat(
                  icon: Icons.water_drop_outlined,
                  value: '${current.humidity}%',
                  label: 'Humidity',
                ),
                _WeatherStat(
                  icon: Icons.air,
                  value: '${current.windSpeed.round()} km/h',
                  label: 'Wind',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('7-day forecast', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final day in weather.daily) _ForecastRow(day: day),
      ],
    );
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.day});

  final DailyForecast day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = isSameDay(day.date, DateTime.now());
    final w = day.weather;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              isToday ? 'Today' : formatShortMonth(day.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(w.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              w.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text('${day.tempMin.round()}°',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(width: 8),
          Text('${day.tempMax.round()}°',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          if (day.precipitationProbability != null)
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, size: 14),
                const SizedBox(width: 2),
                Text('${day.precipitationProbability}%',
                    style: theme.textTheme.bodySmall),
              ],
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _CenterHint extends StatelessWidget {
  const _CenterHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}