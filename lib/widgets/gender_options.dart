import 'package:flutter/material.dart';

import '../models/gender.dart';

/// Vertical list of gender options with radio-style leading icons.
class GenderOptionsList extends StatelessWidget {
  const GenderOptionsList({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Gender? selected;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final gender in Gender.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              selected == gender
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected == gender
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            title: Text(gender.label),
            onTap: () => onChanged(gender),
          ),
      ],
    );
  }
}