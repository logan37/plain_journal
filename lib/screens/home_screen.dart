import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/journal_entry.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart' as utils;
import 'day_screen.dart';
import 'stats_screen.dart';
import 'weather_screen.dart';

/// A single marker event attached to a calendar day.
class _DayMarker {
  const _DayMarker(this.moodColor, this.hasPeriod);
  final Color? moodColor;
  final bool hasPeriod;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.app});

  final AppState app;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final today = utils.dayOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    widget.app.ensureLoaded();
  }

  List<_DayMarker> _eventLoader(DateTime day) {
    final entries = widget.app.entriesForDay(day);
    if (entries.isEmpty) return const [];
    return [
      _DayMarker(
        widget.app.bestMoodForDay(day)?.color,
        widget.app.isPeriodDay(day),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = widget.app;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plain Journal'),
        actions: [
          IconButton(
            tooltip: 'Stats',
            icon: const Icon(Icons.show_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatsScreen(app: app),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DayScreen(app: app, date: _selectedDay),
          ),
        ),
        icon: const Icon(Icons.edit),
        label: const Text('Write entry'),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (!app.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: app.refreshWeather,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                _WeatherBanner(app: app, onTap: _openWeather),
                const SizedBox(height: 12),
                _buildCalendar(theme),
                const SizedBox(height: 12),
                _SelectedDayPanel(
                  app: app,
                  date: _selectedDay,
                  onOpenDay: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DayScreen(app: app, date: _selectedDay),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<_DayMarker>(
          firstDay: DateTime(_focusedDay.year - 2),
          lastDay: DateTime(_focusedDay.year + 1, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _format,
          eventLoader: _eventLoader,
          selectedDayPredicate: (day) => utils.isSameDay(day, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          onFormatChanged: (format) {
            if (_format != format) {
              setState(() => _format = format);
            }
          },
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.week: 'Week',
          },
          availableGestures: AvailableGestures.all,
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: (theme.textTheme.labelSmall ??
                    const TextStyle(fontSize: 11))
                .copyWith(color: theme.colorScheme.outline),
            weekendStyle: (theme.textTheme.labelSmall ??
                    const TextStyle(fontSize: 11))
                .copyWith(color: theme.colorScheme.outline),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            todayTextStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: theme.colorScheme.onPrimaryContainer),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF3B8875),
              shape: BoxShape.circle,
            ),
            selectedTextStyle:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            outsideDaysVisible: false,
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders<_DayMarker>(
            markerBuilder: (context, day, events) {
              final event = events.isNotEmpty ? events.first : null;
              if (event == null) return null;
              return _buildMarkers(event);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMarkers(_DayMarker event) {
    final markers = <Widget>[];
    if (event.moodColor != null) {
      markers.add(Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: event.moodColor,
          shape: BoxShape.circle,
        ),
      ));
    }
    if (event.hasPeriod) {
      markers.add(Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFFE91E63),
          shape: BoxShape.circle,
        ),
      ));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < markers.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          markers[i],
        ],
      ],
    );
  }

  void _openWeather() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WeatherScreen(app: widget.app)),
    );
  }
}

/// Compact city + current-weather summary at the top of the home screen.
class _WeatherBanner extends StatelessWidget {
  const _WeatherBanner({required this.app, required this.onTap});

  final AppState app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = app.city;
    final weather = app.weather;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (city != null) ...[
                      Text(
                        city.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (weather != null)
                        Text(
                          '${weather.current.weather.label}, '
                          '${weather.current.temperature.round()}°',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ] else
                      Text(
                        'Set a city to see weather',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (app.weatherLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom panel summarizing the currently selected day.
class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.app,
    required this.date,
    required this.onOpenDay,
  });

  final AppState app;
  final DateTime date;
  final VoidCallback onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = app.entriesForDay(date);
    final mood = app.bestMoodForDay(date);
    final tags = app.tagsForDay(date);
    final isToday = utils.isSameDay(date, DateTime.now());
    final isPeriod = app.isPeriodDay(date);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    utils.formatFull(date),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (isToday)
                  Chip(
                    label: const Text('Today'),
                    labelStyle: theme.textTheme.labelMedium,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                'No entries yet. Tap below to write one.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              if (mood != null || isPeriod)
                Row(
                  children: [
                    if (mood != null) ...[
                      Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(mood.label, style: theme.textTheme.bodyLarge),
                    ],
                    if (mood != null && isPeriod) const SizedBox(width: 16),
                    if (isPeriod)
                      Chip(
                        avatar: const Icon(
                          Icons.favorite,
                          size: 14,
                          color: Color(0xFFE91E63),
                        ),
                        label: const Text('Period'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in tags)
                      Chip(
                        label: Text('#$tag'),
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          Icons.label_outline,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${entries.length} entr${entries.length == 1 ? 'y' : 'ies'}'
                ' · ${app.tagsForDay(date).isNotEmpty ? '${app.tagsForDay(date).length} tags' : 'no tags'}'
                '${_hasFoods(entries) ? ' · meals logged' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onOpenDay,
              icon: const Icon(Icons.calendar_view_day_outlined),
              label: Text(entries.isEmpty ? 'View & add entries' : 'View entries'),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasFoods(List<JournalEntry> entries) =>
      entries.any((e) => e.foods.isNotEmpty);
}