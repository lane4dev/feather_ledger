import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../models/budget_ui_models.dart';

/// Compact actual-vs-budget summary at the top of the category detail page.
///
/// [showPending] is false for closed months: a month that has ended has no
/// bills left to arrive, so the page tells the actual story only.
class BudgetCategoryProgressCard extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final bool showPending;

  const BudgetCategoryProgressCard({
    super.key,
    required this.row,
    required this.showPending,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final pendingDisplay = showPending ? row.pendingDisplay : null;
    final hasLimit = row.budgetMinor != null && row.budgetMinor! > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _KvMetric(
                  label: l10n.budgetActualSpent,
                  value: row.actualDisplay,
                ),
              ),
              Expanded(
                flex: 2,
                child: _KvMetric(
                  label: l10n.budgetTotal,
                  value: row.budgetDisplay ?? '—',
                ),
              ),
              if (pendingDisplay != null)
                Expanded(
                  flex: 2,
                  child: _KvMetric(
                    label: l10n.budgetPendingShort,
                    value: pendingDisplay,
                    color: colors.frequency,
                  ),
                ),
            ],
          ),
          if (hasLimit) ...[
            SizedBox(height: spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: row.actualProgress,
                minHeight: 6,
                color: row.isOverBudget ? colors.expense : scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
                semanticsLabel: l10n.budgetOverviewBudgetUsage,
              ),
            ),
          ],
          if (row.isAnomaly &&
              row.anomalyPercent != null &&
              row.threeMonthAvgDisplay != null) ...[
            SizedBox(height: spacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.triangleAlert,
                    size: context.metrics.iconSize, color: colors.warning),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    l10n.budgetAnomalyDetail(
                      row.anomalyPercent!,
                      row.threeMonthAvgDisplay!,
                    ),
                    style: AppTypography.meta(context)
                        .copyWith(color: colors.warning),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Committed vs discretionary spend, the pending that still counts, and the
/// reference figures the next budget decision leans on.
///
/// The three reference figures are not additive — committed baseline is what
/// re-commits next month, the other two are last month's actual and the
/// usable three-month average.
class BudgetCategoryCompositionCard extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final bool showPending;
  final bool showMaterializationHint;

  const BudgetCategoryCompositionCard({
    super.key,
    required this.row,
    required this.showPending,
    required this.showMaterializationHint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final pendingDisplay = showPending ? row.pendingDisplay : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetCompositionTitle,
            style: AppTypography.sectionTitle(context),
          ),
          SizedBox(height: spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _KvMetric(
                  label: l10n.budgetCommitted,
                  value: row.committedActualDisplay,
                ),
              ),
              Expanded(
                child: _KvMetric(
                  label: l10n.budgetDiscretionary,
                  value: row.discretionaryActualDisplay,
                ),
              ),
              if (pendingDisplay != null)
                Expanded(
                  child: _KvMetric(
                    label: l10n.budgetPendingShort,
                    value: pendingDisplay,
                    color: context.colors.frequency,
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing.md),
          const FeatherDivider(),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.md,
            runSpacing: spacing.xs,
            children: [
              Text(
                l10n.budgetCommittedRef(row.committedBaselineDisplay),
                style: AppTypography.meta(context),
              ),
              if (row.lastMonthActualDisplay != null)
                Text(
                  l10n.budgetLastMonthRef(row.lastMonthActualDisplay!),
                  style: AppTypography.meta(context),
                ),
              if (row.threeMonthAvgDisplay != null)
                Text(
                  l10n.budgetThreeMoAvgRef(row.threeMonthAvgDisplay!),
                  style: AppTypography.meta(context),
                ),
            ],
          ),
          if (showMaterializationHint) ...[
            SizedBox(height: spacing.sm),
            Text(
              l10n.budgetMaterializedOnlyHint,
              style: AppTypography.compactLabel(context)
                  .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _KvMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _KvMetric({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.meta(context)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.amount(context).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
