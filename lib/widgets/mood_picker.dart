import 'package:flutter/material.dart';

import '../models/mood.dart';

/// Horizontal row of mood options. Tapping selects one; selected is
/// highlighted with the mood color.
class MoodPicker extends StatelessWidget {
  const MoodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Mood? selected;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final mood in Mood.values)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(mood),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected == mood
                        ? mood.color.withValues(alpha: 0.22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected == mood
                          ? mood.color
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    mood.emoji,
                    style: TextStyle(
                      fontSize: selected == mood ? 28 : 24,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected == mood
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected == mood
                        ? mood.color
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}