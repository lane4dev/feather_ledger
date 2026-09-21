import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../view_model/ledger_view_model.dart';

/// Session-only, dismissible banner shown at the top of the ledger when
/// startup materialization adds newly discovered overdue recurring bills.
class OverdueMaterializationBanner extends ConsumerWidget {
  const OverdueMaterializationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(overdueMaterializationCountProvider);
    if (count <= 0) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.xs,
      ),
      child: AppCard.outlined(
        padding: EdgeInsets.only(
          left: spacing.md,
          right: spacing.xs,
          top: spacing.xs,
          bottom: spacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                l10n.overdueBillsAdded(count),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            AppIconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => ref
                  .read(overdueMaterializationCountProvider.notifier)
                  .dismiss(),
            ),
          ],
        ),
      ),
    );
  }
}
