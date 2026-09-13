import 'package:flutter/material.dart';

/// Chip list that lets the user enter free-form values (tags, food items)
/// and remove them by tapping the delete icon.
///
/// Set [suggestions] to render tappable suggestion chips below the input.
class ChipInput extends StatefulWidget {
  const ChipInput({
    super.key,
    required this.label,
    this.icon,
    this.values = const [],
    this.suggestions = const [],
    this.onChanged,
    this.onAddSuggestion,
    this.hintText,
  });

  final String label;
  final IconData? icon;
  final List<String> values;
  final List<String> suggestions;
  final ValueChanged<List<String>>? onChanged;
  final ValueChanged<String>? onAddSuggestion;
  final String? hintText;

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    final values = [...widget.values];
    if (values.contains(value)) {
      _controller.clear();
      setState(() {});
      return;
    }
    values.add(value);
    widget.onChanged?.call(values);
    widget.onAddSuggestion?.call(value);
    _controller.clear();
    setState(() {});
  }

  void _remove(String value) {
    widget.onChanged?.call([...widget.values]..remove(value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.values.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in widget.values)
                InputChip(
                  label: Text(value),
                  onDeleted: () => _remove(value),
                  deleteIconColor: theme.colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText ?? 'Type and press enter',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _add(_controller.text),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: _add,
        ),
        if (widget.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final suggestion in widget.suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _add(suggestion),
                ),
            ],
          ),
        ],
      ],
    );
  }
}