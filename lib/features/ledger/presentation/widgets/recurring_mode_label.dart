import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';

class RecurringModeLabel extends StatelessWidget {
  const RecurringModeLabel({super.key, required this.mode});

  final RecurringSeriesMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, label) = switch (mode) {
      RecurringSeriesMode.planned => (
          LucideIcons.calendar,
          l10n.transactionModePlanned
        ),
      RecurringSeriesMode.repeating => (
          LucideIcons.repeat,
          l10n.transactionModeRepeating
        ),
    };
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      SizedBox(width: context.spacing.xs),
      Text(label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
    ]);
  }
}
