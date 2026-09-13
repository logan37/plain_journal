import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plain_journal/data/local_journal_repository.dart';
import 'package:plain_journal/models/journal_entry.dart';
import 'package:plain_journal/models/mood.dart';
import 'package:plain_journal/models/weather_models.dart';
import 'package:plain_journal/state/app_state.dart';

JournalEntry _entry({
  required String id,
  required DateTime date,
  Mood? mood = Mood.good,
  String content = '',
  List<String> tags = const [],
  List<String> foods = const [],
  bool hasPeriod = false,
}) {
  return JournalEntry(
    id: id,
    date: date,
    mood: mood,
    content: content,
    tags: tags,
    foods: foods,
    hasPeriod: hasPeriod,
    createdAt: date,
  );
}

void main() {
  group('JournalEntry', () {
    test('round-trips through JSON preserving all fields', () {
      final entry = _entry(
        id: 'abc',
        date: DateTime(2026, 9, 13),
        mood: Mood.sad,
        content: 'Rough day',
        tags: ['work', 'health'],
        foods: ['pasta', 'salad'],
        hasPeriod: true,
      );

      final decoded = JournalEntry.fromJson(entry.toJson());

      expect(decoded.id, entry.id);
      expect(decoded.mood, Mood.sad);
      expect(decoded.content, 'Rough day');
      expect(decoded.tags, ['work', 'health']);
      expect(decoded.foods, ['pasta', 'salad']);
      expect(decoded.hasPeriod, isTrue);
      expect(decoded.date, DateTime(2026, 9, 13));
    });

    test('defaults to no mood, no extras', () {
      final entry = _entry(id: 'x', date: DateTime(2026, 1, 1), mood: null);
      final decoded = JournalEntry.fromJson(entry.toJson());
      expect(decoded.mood, isNull);
      expect(decoded.tags, isEmpty);
      expect(decoded.foods, isEmpty);
      expect(decoded.hasPeriod, isFalse);
    });

    test('dateKey is a zero-padded yyyy-MM-dd', () {
      final entry = _entry(id: 'd', date: DateTime(2026, 3, 5), mood: null);
      expect(entry.dateKey, '2026-03-05');
    });

    test('isBlank detects an empty entry', () {
      expect(_entry(id: 'a', date: DateTime(2026), mood: null).isBlank, isTrue);
      expect(_entry(id: 'a', date: DateTime(2026), content: 'hi').isBlank, isFalse);
      expect(_entry(id: 'a', date: DateTime(2026), hasPeriod: true).isBlank, isFalse);
    });
  });

  group('Mood', () {
    test('fromName resolves valid and unknown names', () {
      expect(Mood.fromName('great'), Mood.great);
      expect(Mood.fromName('nope'), isNull);
      expect(Mood.fromName(null), isNull);
    });
  });

  group('CityLocation', () {
    test('round-trips and builds a display name', () {
      final city = const CityLocation(
        id: 1,
        name: 'Berlin',
        country: 'Germany',
        region: 'Berlin',
        latitude: 52.52,
        longitude: 13.405,
      );
      final decoded = CityLocation.fromJson(city.toJson());
      expect(decoded.latitude, 52.52);
      expect(decoded.displayName, 'Berlin, Berlin, Germany');
    });
  });

  group('LocalJournalRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('save then load returns sorted entries', () async {
      final repo = LocalJournalRepository();
      final later = _entry(id: '2', date: DateTime(2026, 9, 13));
      final earlier = _entry(id: '1', date: DateTime(2026, 9, 1));

      await repo.saveEntries([later, earlier]);
      final loaded = await repo.loadEntries();

      expect(loaded.map((e) => e.id), ['1', '2']);
    });

    test('persists a city selection', () async {
      final repo = LocalJournalRepository();
      expect(await repo.loadCity(), isNull);

      await repo.saveCity(const CityLocation(
        id: 9,
        name: 'Tokyo',
        country: 'Japan',
        latitude: 35.68,
        longitude: 139.69,
      ));

      final city = await repo.loadCity();
      expect(city, isNotNull);
      expect(city!.name, 'Tokyo');
    });

    test('persists custom tags', () async {
      final repo = LocalJournalRepository();
      await repo.saveCustomTags(['focus', 'focus', 'books']);
      expect(await repo.loadCustomTags(), ['focus', 'books']);
    });
  });

  group('AppState', () {
    late AppState app;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      app = AppState(repository: LocalJournalRepository());
    });

    test('adds and deletes entries persistently', () async {
      await app.ensureLoaded();
      await app.addEntry(_entry(id: 'e1', date: DateTime(2026, 9, 13)));
      expect(app.entries.length, 1);
      expect(app.entriesForDay(DateTime(2026, 9, 13)).length, 1);

      await app.deleteEntry('e1');
      expect(app.entries, isEmpty);

      // Reloads from disk after a fresh instance.
      final fresh = AppState(repository: LocalJournalRepository());
      await fresh.ensureLoaded();
      expect(fresh.entries, isEmpty);
    });

    test('bestMoodForDay prefers the most positive mood', () async {
      await app.ensureLoaded();
      await app.addEntry(_entry(id: '1', date: DateTime(2026, 9, 13), mood: Mood.sad));
      await app.addEntry(
          _entry(id: '2', date: DateTime(2026, 9, 13), mood: Mood.good));

      expect(app.bestMoodForDay(DateTime(2026, 9, 13)), Mood.good);
    });

    test('period flags roll up into isPeriodDay and periodDayCount', () async {
      await app.ensureLoaded();
      await app.addEntry(
          _entry(id: '1', date: DateTime(2026, 9, 13), hasPeriod: true, mood: null));
      await app.addEntry(_entry(id: '2', date: DateTime(2026, 9, 14), mood: null));

      expect(app.isPeriodDay(DateTime(2026, 9, 13)), isTrue);
      expect(app.isPeriodDay(DateTime(2026, 9, 14)), isFalse);
      expect(app.periodDayCount, 1);
    });

    test('daysWithEntries and totalDays reflect distinct days', () async {
      await app.ensureLoaded();
      await app.addEntry(_entry(id: '1', date: DateTime(2026, 9, 13), mood: null));
      await app.addEntry(_entry(id: '2', date: DateTime(2026, 9, 13), mood: null));
      await app.addEntry(_entry(id: '3', date: DateTime(2026, 9, 14), mood: null));

      expect(app.daysWithEntries.length, 2);
      expect(app.totalDays, 2);
      expect(app.totalEntries, 3);
    });

    test('moodSeriesForMonth fills weights by day index', () async {
      await app.ensureLoaded();
      await app.addEntry(_entry(id: '1', date: DateTime(2026, 5, 2), mood: Mood.great));

      final series = app.moodSeriesForMonth(DateTime(2026, 5));
      expect(series.length, 31);
      expect(series[1], 5);
      expect(series[0], 0);
    });

    test('tagCounts and custom tags', () async {
      await app.ensureLoaded();
      await app.addEntry(_entry(id: '1', date: DateTime(2026, 9, 13), tags: ['work', 'food']));
      await app.addEntry(_entry(id: '2', date: DateTime(2026, 9, 14), tags: ['work']));

      final counts = app.tagCounts();
      expect(counts['work'], 2);
      expect(counts['food'], 1);

      app.addCustomTag('focus');
      expect(app.customTags, ['focus']);
      expect(app.allTags, contains('focus'));
    });
  });
}