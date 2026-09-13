import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/mood.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/chip_input.dart';
import '../widgets/mood_picker.dart';

/// Create or edit a single journal entry (one per day is enough for most
/// people, but multiple entries per day are supported).
class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({
    super.key,
    required this.app,
    required this.date,
    this.entry,
  });

  final AppState app;
  final DateTime date;
  final JournalEntry? entry;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late final TextEditingController _contentController;
  late final bool _isEditing;
  Mood? _mood;
  late List<String> _tags;
  late List<String> _foods;
  late bool _hasPeriod;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _isEditing = entry != null;
    _mood = entry?.mood;
    _tags = [...?entry?.tags];
    _foods = [...?entry?.foods];
    _hasPeriod = entry?.hasPeriod ?? false;
    _contentController =
        TextEditingController(text: entry?.content ?? '')
          ..selection = TextSelection.collapsed(offset: -1);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty &&
        _mood == null &&
        _tags.isEmpty &&
        _foods.isEmpty &&
        !_hasPeriod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save')),
      );
      return;
    }

    final now = DateTime.now();
    if (_isEditing) {
      final updated = widget.entry!.copyWith(
        mood: _mood,
        content: content,
        tags: _tags,
        foods: _foods,
        hasPeriod: _hasPeriod,
      );
      await widget.app.updateEntry(updated);
    } else {
      await widget.app.addEntry(JournalEntry(
        id: '${now.microsecondsSinceEpoch}',
        date: widget.date,
        mood: _mood,
        content: content,
        tags: _tags,
        foods: _foods,
        hasPeriod: _hasPeriod,
        createdAt: now,
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = widget.app.allTags
      ..removeWhere(_tags.contains);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit entry' : formatShort(widget.date)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            formatFull(widget.date),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Text('How are you feeling?',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
              )),
          const SizedBox(height: 8),
          MoodPicker(
            selected: _mood,
            onChanged: (mood) => setState(() => _mood = mood),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _contentController,
            minLines: 4,
            maxLines: 12,
            decoration: InputDecoration(
              labelText: 'Journal notes',
              hintText: 'What happened today?',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ChipInput(
            label: 'What did you eat?',
            icon: Icons.restaurant_outlined,
            values: _foods,
            onChanged: (values) => setState(() => _foods = values),
            hintText: 'e.g. oatmeal, salad, coffee',
          ),
          const SizedBox(height: 24),
          ChipInput(
            label: 'Tags',
            icon: Icons.label_outline,
            values: _tags,
            suggestions: suggestions,
            onChanged: (values) => setState(() => _tags = values),
            onAddSuggestion: widget.app.addCustomTag,
            hintText: 'Add a tag',
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Period day'),
            subtitle: const Text('Mark this day for cycle tracking'),
            secondary: const Icon(
              Icons.favorite,
              color: Color(0xFFE91E63),
            ),
            value: _hasPeriod,
            onChanged: (value) => setState(() => _hasPeriod = value),
          ),
        ],
      ),
    );
  }
}