import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/weather_models.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import 'entry_editor_screen.dart';

/// Shows everything logged for a single day: weather for that date,
/// the journal entries, meals, mood and period marker.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.app, required this.date});

  final AppState app;
  final DateTime date;

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(title: Text(formatFull(widget.date))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final entries = app.entriesForDay(widget.date);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            children: [
              _DayWeather(app: app, date: widget.date),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const _EmptyState()
              else
                for (final entry in entries)
                  _EntryCard(
                    entry: entry,
                    onEdit: () => _editEntry(entry),
                    onDelete: () => _deleteEntry(entry),
                  ),
            ],
          );
        },
      ),
    );
  }

  void _addEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(
          app: widget.app,
          date: widget.date,
        ),
      ),
    );
  }

  void _editEntry(JournalEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryEditorScreen(
          app: widget.app,
          date: entry.date,
          entry: entry,
        ),
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.app.deleteEntry(entry.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing logged for this day yet.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Use "New entry" to add a journal entry,\nmeal notes, mood, tags or a period marker.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Forecast snippet for the selected day, if the saved city has weather.
class _DayWeather extends StatelessWidget {
  const _DayWeather({required this.app, required this.date});

  final AppState app;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final weather = app.weather;
    if (weather == null) return const SizedBox.shrink();

    DailyForecast? day;
    for (final forecast in weather.daily) {
      if (isSameDay(forecast.date, date)) {
        day = forecast;
        break;
      }
    }
    if (day == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final w = day.weather;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(w.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${day.tempMin.round()}° / ${day.tempMax.round()}°',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (day.precipitationProbability != null)
              Row(
                children: [
                  const Icon(Icons.water_drop_outlined, size: 16),
                  const SizedBox(width: 2),
                  Text('${day.precipitationProbability}%'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = _timeOfDay(entry.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                if (entry.mood != null)
                  Text(
                    entry.mood!.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                if (entry.mood != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    createdAt,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (entry.hasPeriod)
                  const Icon(Icons.favorite, size: 18, color: Color(0xFFE91E63)),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (sheetContext) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Edit entry'),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onEdit();
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            title: const Text('Delete entry'),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onDelete();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (entry.content.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(entry.content.trim()),
            ],
            if (entry.foods.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionLabel(
                icon: Icons.restaurant_outlined,
                label: 'Ate',
                items: entry.foods,
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in entry.tags)
                    Chip(
                      label: Text('#$tag'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label, required this.items});

  final IconData icon;
  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.outline),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(items.join(' · ')),
      ],
    );
  }
}

String _timeOfDay(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}