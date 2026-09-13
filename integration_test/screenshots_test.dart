import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plain_journal/data/local_journal_repository.dart';
import 'package:plain_journal/main.dart' as app;
import 'package:plain_journal/models/journal_entry.dart';
import 'package:plain_journal/models/mood.dart';
import 'package:plain_journal/state/app_state.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture marketing screenshots', (tester) async {
    final today = DateTime.now();
    final day = (int daysBack) =>
        DateTime(today.year, today.month, today.day).subtract(
          Duration(days: daysBack),
        );

    final state = AppState(repository: LocalJournalRepository());
    await state.ensureLoaded();

    Future<void> seed(
      DateTime date, {
      Mood? mood,
      String content = '',
      List<String> foods = const [],
      List<String> tags = const [],
      bool period = false,
    }) {
      return state.addEntry(
        JournalEntry(
          id: '${date.microsecondsSinceEpoch}-${mood?.name}',
          date: date,
          mood: mood,
          content: content,
          tags: tags,
          foods: foods,
          hasPeriod: period,
          createdAt: DateTime(date.year, date.month, date.day, 9),
        ),
      );
    }

    await seed(
      day(0),
      mood: Mood.great,
      content: 'Morning run in the park, then coffee with Maya. '
          'Great energy all day!',
      foods: const ['overnight oats', 'salad'],
      tags: const ['exercise', 'friends'],
    );
    await seed(
      day(1),
      mood: Mood.good,
      content: 'Finished the migration at work. Team dinner was fun.',
      foods: const ['pizza', 'salad'],
      tags: const ['work', 'friends'],
    );
    await seed(
      day(2),
      mood: Mood.neutral,
      content: 'Rainy day. Stayed in and read a book.',
      foods: const ['soup'],
      tags: const ['ideas'],
    );
    await seed(
      day(3),
      mood: Mood.sad,
      content: 'Feeling low today - skipped the gym and slept late.',
      tags: const ['health'],
      period: true,
    );
    await seed(
      day(4),
      mood: Mood.terrible,
      content: 'Long night, big headache. Coffee was a lifesaver.',
      foods: const ['coffee'],
      tags: const ['health', 'sleep'],
    );
    await seed(day(6), mood: Mood.good, tags: const ['health'], period: true);
    await seed(
      day(9),
      mood: Mood.neutral,
      content: 'Quiet Sunday. Walked around the lake.',
      tags: const ['health'],
    );

    await tester.pumpWidget(app.PlainJournalApp(app: state));
    await tester.pumpAndSettle();

    await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 300));

    await binding.takeScreenshot('01_home');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('View entries'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_day');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('New entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Great'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.enterText(
      find.byType(TextField).first,
      'Sunny afternoon. Got a lot done.',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await binding.takeScreenshot('03_editor');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Stats'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('04_stats');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set a city to see weather'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05_weather');
    await tester.pump(const Duration(milliseconds: 400));
  });
}