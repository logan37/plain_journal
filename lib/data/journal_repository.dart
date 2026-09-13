import '../models/journal_entry.dart';
import '../models/weather_models.dart';

/// Abstraction over where journal data lives.
///
/// The app only talks to this interface, so a remote/cloud repository that
/// implements the same contract can be swapped in later without touching any
/// UI code.
abstract class JournalRepository {
  /// Loads every journal entry, oldest first.
  Future<List<JournalEntry>> loadEntries();

  /// Persists the full set of entries (replace-all semantics).
  Future<void> saveEntries(List<JournalEntry> entries);

  /// The user's saved weather location, or null if never set.
  Future<CityLocation?> loadCity();

  Future<void> saveCity(CityLocation city);

  /// Custom tags the user has created beyond the built-in defaults.
  Future<List<String>> loadCustomTags();
  Future<void> saveCustomTags(List<String> tags);
}