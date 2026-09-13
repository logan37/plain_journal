import 'mood.dart';
import '../utils/date_utils.dart' as dates;

/// A single journal entry for a given day.
///
/// A day may hold multiple entries (e.g. one in the morning, one at night).
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.date,
    this.mood,
    this.content = '',
    this.tags = const [],
    this.foods = const [],
    this.hasPeriod = false,
    required this.createdAt,
  });

  final String id;

  /// The day this entry belongs to, normalized to date-only.
  final DateTime date;

  final Mood? mood;
  final String content;
  final List<String> tags;

  /// What the user ate that day.
  final List<String> foods;

  /// Whether the user is on their period this day (for cycle tracking).
  final bool hasPeriod;

  final DateTime createdAt;

  bool get hasMood => mood != null;

  bool get isBlank => content.trim().isEmpty && tags.isEmpty && foods.isEmpty && !hasPeriod;

  String get dateKey => dates.dateKey(date);

  JournalEntry copyWith({
    Mood? mood,
    String? content,
    List<String>? tags,
    List<String>? foods,
    bool? hasPeriod,
  }) {
    return JournalEntry(
      id: id,
      date: date,
      mood: mood ?? this.mood,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      foods: foods ?? this.foods,
      hasPeriod: hasPeriod ?? this.hasPeriod,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': dates.dateKey(date),
      'mood': mood?.name,
      'content': content,
      'tags': tags,
      'foods': foods,
      'hasPeriod': hasPeriod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: Mood.fromName(json['mood'] as String?),
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      foods: (json['foods'] as List?)?.cast<String>() ?? const [],
      hasPeriod: json['hasPeriod'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
