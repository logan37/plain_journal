import 'package:flutter/material.dart';

/// A mood is a 5-point emotional scale used to tag a journal entry.
enum Mood {
  terrible(
    label: 'Terrible',
    emoji: '😭',
    color: Color(0xFF8E24AA),
    weight: 1,
  ),
  sad(
    label: 'Sad',
    emoji: '😞',
    color: Color(0xFF5C6BC0),
    weight: 2,
  ),
  neutral(
    label: 'Okay',
    emoji: '😐',
    color: Color(0xFF90A4AE),
    weight: 3,
  ),
  good(
    label: 'Good',
    emoji: '🙂',
    color: Color(0xFF26A69A),
    weight: 4,
  ),
  great(
    label: 'Great',
    emoji: '😄',
    color: Color(0xFFFFB300),
    weight: 5,
  );

  const Mood({
    required this.label,
    required this.emoji,
    required this.color,
    required this.weight,
  });

  final String label;
  final String emoji;
  final Color color;
  final int weight;

  static Mood? fromName(String? name) {
    for (final mood in Mood.values) {
      if (mood.name == name) return mood;
    }
    return null;
  }
}