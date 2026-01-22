import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import '../providers/reports_providers.dart';

class HeatmapModeDropdown extends ConsumerWidget {
  const HeatmapModeDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(heatmapModeStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return DropdownButton<HeatmapMode>(
      value: mode,
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
      onChanged: (HeatmapMode? newValue) {
        if (newValue != null) {
          ref.read(heatmapModeStateProvider.notifier).setMode(newValue);
        }
      },
      items: [
        DropdownMenuItem(
          value: HeatmapMode.frequency,
          child: Text(l10n.reports == 'Reports' ? 'Frequency' : '频率'),
        ),
        DropdownMenuItem(
          value: HeatmapMode.amount,
          child: Text(l10n.amount),
        ),
      ],
    );
  }
}
