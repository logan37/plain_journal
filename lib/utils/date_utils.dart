import 'package:intl/intl.dart';

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String dateKey(DateTime date) => dateKeyFrom(dayOnly(date).year, dayOnly(date).month, dayOnly(date).day);

String dateKeyFrom(int year, int month, int day) {
  final mm = month.toString().padLeft(2, '0');
  final dd = day.toString().padLeft(2, '0');
  return '$year-$mm-$dd';
}

String formatFull(DateTime date) => DateFormat('EEEE, MMMM d, y').format(date);

String formatShort(DateTime date) => DateFormat('EEE, MMM d').format(date);

String formatMonth(DateTime date) => DateFormat('MMMM yyyy').format(date);

String formatShortMonth(DateTime date) => DateFormat('MMM d').format(date);