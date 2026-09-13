import 'package:flutter/material.dart';

import 'data/local_journal_repository.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState(repository: LocalJournalRepository());
  runApp(PlainJournalApp(app: app));
}

class PlainJournalApp extends StatelessWidget {
  const PlainJournalApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B8875),
    );
    return MaterialApp(
      title: 'Plain Journal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: scheme.surface,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: HomeScreen(app: app),
    );
  }
}