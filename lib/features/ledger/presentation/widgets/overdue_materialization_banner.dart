import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../view_model/ledger_view_model.dart';

/// Session-only, dismissible banner shown at the top of the ledger when
/// startup materialization adds newly discovered overdue recurring bills,
/// truncates long-dormant history, or trips the auto-post circuit breaker.
class OverdueMaterializationBanner extends ConsumerWidget {
  const OverdueMaterializationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(overdueMaterializationNoticeProvider);
    if (!notice.isVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final spacing = context.spacing;

    final messages = <String>[
      if (notice.overdueCount > 0) l10n.overdueBillsAdded(notice.overdueCount),
      if (notice.hasTruncatedHistory) l10n.overdueBillsTruncatedNotice,
      if (notice.circuitBreakerLatchedCount > 0)
        l10n.autoPostCircuitBreakerNotice(notice.circuitBreakerLatchedCount),
    ];

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.clock,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    messages.first,
                    style: theme.textTheme.bodyMedium,
                  ),
                  for (final secondary in messages.skip(1)) ...[
                    SizedBox(height: spacing.xs),
                    Text(
                      secondary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppIconButton(
              icon: const Icon(LucideIcons.x, size: 18),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => ref
                  .read(overdueMaterializationNoticeProvider.notifier)
                  .dismiss(),
            ),
          ],
        ),
      ),
    );
  }
}
