import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/journal_repository.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';
import '../utils/date_utils.dart';

/// Built-in tag suggestions shown in the editor alongside custom ones.
const kDefaultTags = <String>[
  'work',
  'health',
  'family',
  'friends',
  'food',
  'sleep',
  'exercise',
  'travel',
  'ideas',
  'gratitude',
];

/// Central application state.
///
/// Holds every journal entry in memory, persists through [repository], and
/// provides derived lookups (by-day events, period days, stats) used by the
/// UI. Listening to this notifier rebuilds the whole app when data changes.
class AppState extends ChangeNotifier {
  AppState({
    required this.repository,
    WeatherService? weatherService,
  }) : weatherService = weatherService ?? WeatherService();

  final JournalRepository repository;
  final WeatherService weatherService;

  bool _loaded = false;
  List<JournalEntry> _entries = [];
  Map<String, List<JournalEntry>> _byDateKey = {};

  CityLocation? _city;
  List<String> _customTags = [];

  WeatherBundle? _weather;
  String? _weatherError;
  bool _weatherLoading = false;

  bool get loaded => _loaded;
  List<JournalEntry> get entries => List.unmodifiable(_entries);

  CityLocation? get city => _city;
  List<String> get customTags => List.unmodifiable(_customTags);
  WeatherBundle? get weather => _weather;
  bool get weatherLoading => _weatherLoading;
  String? get weatherError => _weatherError;

  List<String> get allTags {
    final set = kDefaultTags.toSet()
      ..addAll(_customTags)
      ..addAll(_entries.expand((e) => e.tags));
    final list = set.toList()..sort();
    return list;
  }

  /// Initial load from storage; safe to call multiple times.
  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final results = await Future.wait([
      repository.loadEntries(),
      repository.loadCity(),
      repository.loadCustomTags(),
    ]);

    _entries = results[0] as List<JournalEntry>;
    _city = results[1] as CityLocation?;
    _customTags = results[2] as List<String>;

    _index();
    _loaded = true;
    notifyListeners();

    if (_city != null) {
      unawaited(refreshWeather());
    }
  }

  void _index() {
    final map = <String, List<JournalEntry>>{};
    for (final e in _entries) {
      map.putIfAbsent(e.dateKey, () => []).add(e);
    }
    _byDateKey = map;
  }

  List<JournalEntry> entriesForDay(DateTime day) =>
      _byDateKey[dateKey(day)] ?? const [];

  /// Non-null mood for a day: preference for the "best" (most positive) entry.
  Mood? bestMoodForDay(DateTime day) {
    final list = entriesForDay(day);
    Mood? best;
    for (final e in list) {
      if (e.mood != null &&
          (best == null || e.mood!.weight > best.weight)) {
        best = e.mood;
      }
    }
    return best;
  }

  bool isPeriodDay(DateTime day) =>
      entriesForDay(day).any((e) => e.hasPeriod);

  /// Distinct tags used on a given day, sorted.
  List<String> tagsForDay(DateTime day) {
    final set = <String>{};
    for (final e in entriesForDay(day)) {
      set.addAll(e.tags);
    }
    return set.toList()..sort();
  }

  Set<DateTime> get daysWithEntries =>
      _byDateKey.keys.map(DateTime.parse).toSet();

  // ---- Mutations ---------------------------------------------------------

  Future<void> addEntry(JournalEntry entry) async {
    _entries.add(entry);
    await _persist();
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) return;
    _entries[index] = entry;
    await _persist();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    _entries.sort((a, b) => a.date.compareTo(b.date));
    _index();
    notifyListeners();
    await repository.saveEntries(_entries);
  }

  void addCustomTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _customTags.contains(trimmed)) return;
    _customTags.add(trimmed);
    repository.saveCustomTags(_customTags);
    notifyListeners();
  }

  // ---- Weather -----------------------------------------------------------

  Future<void> setCity(CityLocation city) async {
    _city = city;
    notifyListeners();
    await repository.saveCity(city);
    await refreshWeather();
  }

  Future<void> refreshWeather() async {
    final city = _city;
    if (city == null) return;
    _weatherLoading = true;
    _weatherError = null;
    notifyListeners();
    try {
      _weather = await weatherService.fetchForecast(city);
    } catch (e) {
      _weather = null;
      _weatherError = 'Could not load weather: $e';
    } finally {
      _weatherLoading = false;
      notifyListeners();
    }
  }

  // ---- Stats -------------------------------------------------------------

  int get totalEntries => _entries.length;

  int get totalDays => _byDateKey.length;

  int get periodDayCount => _entries.where((e) => e.hasPeriod).length;

  /// Longest run of consecutive days (ending today or yesterday) with entries.
  int get currentStreak {
    final days = daysWithEntries;
    if (days.isEmpty) return 0;

    var streak = 0;
    var cursor = dayOnly(DateTime.now());
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Map of mood -> count over the last [days] entries' period, or all if 0.
  Map<Mood, int> moodCounts({int? lookback}) {
    var recent = _entries;
    if (lookback != null && _entries.isNotEmpty) {
      final oldest = _entries[_entries.length - lookback.clamp(0, _entries.length)];
      recent = _entries.where((e) => !e.date.isBefore(oldest.date)).toList();
    }
    final counts = <Mood, int>{};
    for (final e in recent) {
      if (e.mood != null) {
        counts[e.mood!] = (counts[e.mood!] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> tagCounts() {
    final counts = <String, int>{};
    for (final e in _entries) {
      for (final tag in e.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return LinkedHashMap.fromEntries(sorted);
  }

  /// Mood weights for each day of [month], index = day - 1 (0 when absent).
  List<int> moodSeriesForMonth(DateTime month) {
    final weights = List<int>.filled(
      DateTime(month.year, month.month + 1, 0).day,
      0,
    );
    for (final e in _entries) {
      if (e.date.year == month.year && e.date.month == month.month && e.mood != null) {
        weights[e.date.day - 1] = max(weights[e.date.day - 1], e.mood!.weight);
      }
    }
    return weights;
  }
}