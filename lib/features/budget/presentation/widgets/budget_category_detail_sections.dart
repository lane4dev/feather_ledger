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

  static const double _barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final pendingDisplay = showPending ? row.pendingDisplay : null;
    final hasLimit = row.budgetMinor != null && row.budgetMinor! > 0;
    final headline = _headlineText(l10n, row);
    final headlineColor = switch (row.mainAmountTone) {
      BudgetCategoryAmountTone.neutral => scheme.onSurface,
      BudgetCategoryAmountTone.positive => colors.income,
      BudgetCategoryAmountTone.warning => colors.warning,
      BudgetCategoryAmountTone.negative => colors.expense,
    };
    final actualColor = row.isOverBudget ? colors.expense : scheme.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headline != null) ...[
            FittedBox(
              key: const ValueKey('budget-detail-headline'),
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                headline,
                style: AppTypography.statistic(context)
                    .copyWith(color: headlineColor),
              ),
            ),
            SizedBox(height: spacing.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _KvMetric(
                  key: const ValueKey('budget-detail-metric-spent'),
                  label: l10n.budgetActualSpent,
                  value: row.actualDisplay,
                ),
              ),
              if (pendingDisplay != null)
                Expanded(
                  child: _KvMetric(
                    key: const ValueKey('budget-detail-metric-pending'),
                    label: l10n.budgetPendingShort,
                    value: pendingDisplay,
                    color: colors.frequency,
                  ),
                ),
              Expanded(
                child: _KvMetric(
                  key: const ValueKey('budget-detail-metric-budget'),
                  label: l10n.budgetTotal,
                  value: row.budgetDisplay ?? '—',
                ),
              ),
            ],
          ),
          if (hasLimit) ...[
            SizedBox(height: spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: _barHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          key: const ValueKey('budget-detail-bar'),
                          color: scheme.surfaceContainerHighest,
                        ),
                        if (row.actualProgress > 0)
                          Positioned(
                            left: 0,
                            width: width * row.actualProgress,
                            top: 0,
                            bottom: 0,
                            child: ColoredBox(
                              key: const ValueKey(
                                'budget-detail-bar-actual',
                              ),
                              color: actualColor,
                            ),
                          ),
                        if (row.pendingProgress > 0)
                          Positioned(
                            left: width * row.actualProgress,
                            width: width * row.pendingProgress,
                            top: 0,
                            bottom: 0,
                            child: ColoredBox(
                              key: const ValueKey(
                                'budget-detail-bar-pending',
                              ),
                              color: colors.frequency.withValues(alpha: 0.65),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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

/// Committed vs discretionary spend, and the two reference figures the next
/// budget decision leans on.
///
/// The figures are not additive — the committed baseline is what re-commits
/// next month, and last month's actual is the comparison that keeps the split
/// honest. The three-month average stays on the trend chart, where it belongs.
class BudgetCategoryCompositionCard extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final bool showMaterializationHint;

  const BudgetCategoryCompositionCard({
    super.key,
    required this.row,
    required this.showMaterializationHint,
  });

  static const double _barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final fixedShare = row.committedShare.clamp(0.0, 1.0);
    final references = [
      l10n.budgetCommittedRef(row.committedBaselineDisplay),
      if (row.lastMonthActualDisplay != null)
        l10n.budgetLastMonthRef(row.lastMonthActualDisplay!),
    ];

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
                  key: const ValueKey('budget-composition-metric-fixed'),
                  label: l10n.budgetCommitted,
                  value: row.committedActualDisplay,
                ),
              ),
              Expanded(
                child: _KvMetric(
                  key: const ValueKey('budget-composition-metric-flexible'),
                  label: l10n.budgetDiscretionary,
                  value: row.discretionaryActualDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: _barHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    key: const ValueKey('budget-composition-bar'),
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        key: const ValueKey('budget-composition-bar-track'),
                        color: scheme.surfaceContainerHighest,
                      ),
                      if (row.hasActualSpend && fixedShare > 0)
                        Positioned(
                          left: 0,
                          width: width * fixedShare,
                          top: 0,
                          bottom: 0,
                          child: ColoredBox(
                            key: const ValueKey(
                              'budget-composition-bar-fixed',
                            ),
                            color: scheme.primary,
                          ),
                        ),
                      if (row.hasActualSpend && fixedShare < 1)
                        Positioned(
                          left: width * fixedShare,
                          width: width * (1 - fixedShare),
                          top: 0,
                          bottom: 0,
                          child: ColoredBox(
                            key: const ValueKey(
                              'budget-composition-bar-flexible',
                            ),
                            color: colors.frequency.withValues(alpha: 0.65),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(height: spacing.md),
          const FeatherDivider(),
          SizedBox(height: spacing.sm),
          Text(
            references.join(' · '),
            style: AppTypography.meta(context),
          ),
          if (showMaterializationHint) ...[
            SizedBox(height: spacing.sm),
            Text(
              l10n.budgetMaterializedOnlyHint,
              style: AppTypography.compactLabel(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

String? _headlineText(
  AppLocalizations l10n,
  BudgetCategoryRowUiModel row,
) {
  final amount = row.mainAmountDisplay;
  if (amount == null) return null;
  return switch (row.amountLabel) {
    BudgetCategoryAmountLabel.none => null,
    BudgetCategoryAmountLabel.remaining => l10n.budgetRowRemaining(amount),
    BudgetCategoryAmountLabel.projectedRemaining =>
      l10n.budgetRowProjectedRemaining(amount),
    BudgetCategoryAmountLabel.projectedOver =>
      l10n.budgetRowProjectedOver(amount),
    BudgetCategoryAmountLabel.over => l10n.budgetRowOver(amount),
    BudgetCategoryAmountLabel.reviewRemaining =>
      l10n.budgetRowReviewRemaining(amount),
    BudgetCategoryAmountLabel.reviewOver => l10n.budgetRowReviewOver(amount),
    BudgetCategoryAmountLabel.planBudget => l10n.budgetRowPlanBudget(amount),
  };
}

class _KvMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _KvMetric({
    super.key,
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
