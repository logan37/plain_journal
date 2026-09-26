import 'package:flutter/material.dart';

import '../models/gender.dart';
import '../state/app_state.dart';
import '../widgets/gender_options.dart';

/// App preferences: currently the user's gender, which controls whether
/// period tracking appears anywhere in the app.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.app});

  final AppState app;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Gender? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final selected = _selected ?? app.gender;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Tracking preferences', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: GenderOptionsList(
                    selected: selected,
                    onChanged: (gender) {
                      setState(() => _selected = gender);
                      app.setGender(gender);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                app.showPeriodTracking
                    ? 'Period tracking is enabled and visible throughout the app.'
                    : 'Period tracking is hidden. It is shown only when gender '
                          'is set to Female.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// First-run dialog asking the user to choose a gender.
///
/// The dialog cannot be dismissed without making a choice so that period
/// tracking visibility is always defined after onboarding.
class GenderOnboardingDialog extends StatefulWidget {
  const GenderOnboardingDialog({super.key, required this.app});

  final AppState app;

  @override
  State<GenderOnboardingDialog> createState() => _GenderOnboardingDialogState();
}

class _GenderOnboardingDialogState extends State<GenderOnboardingDialog> {
  Gender? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      scrollable: true,
      title: const Text('Welcome to Plain Journal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To tailor tracking to you, which option describes your '
            'gender? Period tracking is shown only for Female.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GenderOptionsList(
            selected: _selected,
            onChanged: (gender) => setState(() => _selected = gender),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _selected == null
              ? null
              : () async {
                  final gender = _selected!;
                  await widget.app.setGender(gender);
                  if (context.mounted) Navigator.of(context).pop();
                },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}