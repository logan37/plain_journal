import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journal_entry.dart';
import '../models/weather_models.dart';
import 'journal_repository.dart';

/// SharedPreferences-backed repository.
///
/// Journal data is stored in one JSON document under [entriesKey]. This is
/// intentionally simple; the [JournalRepository] contract keeps the door open
/// for migrating to a real local database (drift/sqlite) or a cloud backend.
class LocalJournalRepository implements JournalRepository {
  static const _entriesKey = 'journal.entries';
  static const _cityKey = 'journal.city';
  static const _customTagsKey = 'journal.customTags';

  @override
  Future<List<JournalEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => a.date.compareTo(b.date));
      return entries;
    } catch (_) {
      // Corrupted data should not crash the app on startup.
      return [];
    }
  }

  @override
  Future<void> saveEntries(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, raw);
  }

  @override
  Future<CityLocation?> loadCity() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cityKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CityLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCity(CityLocation city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, jsonEncode(city.toJson()));
  }

  @override
  Future<List<String>> loadCustomTags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customTagsKey) ?? [];
  }

  @override
  Future<void> saveCustomTags(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customTagsKey, tags.toSet().toList());
  }
}