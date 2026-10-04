import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_ui_models.dart';

class BudgetOverviewCard extends StatelessWidget {
  final BudgetOverviewUiModel overview;

  const BudgetOverviewCard({
    super.key,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    final modeLabel = switch (overview.mode) {
      BudgetMode.plan => l10n.budgetModePlan,
      BudgetMode.track => l10n.budgetModeTrack,
      BudgetMode.review => l10n.budgetModeReview,
    };

    final actualColor =
        overview.isProjectedOverBudget && !overview.hasBudgetedPending
            ? scheme.error
            : scheme.primary;
    final remainingColor = overview.isProjectedOverBudget
        ? context.colors.expense
        : context.colors.income;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppBadge(label: modeLabel, color: scheme.primary),
              AppBadge(
                label: '${l10n.budgetCompliance} ${overview.complianceDisplay}',
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Text(l10n.budgetTotal, style: AppTypography.meta(context)),
          SizedBox(height: spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              overview.hasAnyBudget ? overview.totalBudgetDisplay : '—',
              style: AppTypography.balance(context),
            ),
          ),
          SizedBox(height: spacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: scheme.surfaceContainerHighest,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final actualWidth = width * overview.actualRatio;
                  final pendingWidth = width * overview.pendingRatio;
                  return Row(
                    children: [
                      if (actualWidth > 0)
                        Container(width: actualWidth, color: actualColor),
                      if (pendingWidth > 0)
                        Container(
                          width: pendingWidth,
                          color:
                              context.colors.frequency.withValues(alpha: 0.65),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: l10n.budgetActualSpent,
                  value: overview.budgetedActualDisplay,
                  color: scheme.onSurface,
                ),
              ),
              if (overview.mode != BudgetMode.review &&
                  overview.hasBudgetedPending)
                Expanded(
                  child: _MetricColumn(
                    label: l10n.budgetPendingShort,
                    value: overview.budgetedPendingDisplay,
                    color: context.colors.frequency,
                  ),
                ),
              Expanded(
                child: _MetricColumn(
                  label: overview.isProjectedOverBudget
                      ? l10n.budgetProjectedOver
                      : l10n.budgetProjectedRemaining,
                  value: overview.projectedRemainingDisplay,
                  color: overview.hasAnyBudget
                      ? remainingColor
                      : scheme.onSurfaceVariant,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.md,
            runSpacing: spacing.xs,
            children: [
              _InlineChipStat(
                icon: LucideIcons.calendarClock,
                label:
                    '${l10n.budgetCommitted}: ${overview.committedActualDisplay}',
              ),
              _InlineChipStat(
                icon: LucideIcons.shoppingBag,
                label:
                    '${l10n.budgetDiscretionary}: ${overview.discretionaryActualDisplay}',
              ),
              if (overview.mode != BudgetMode.review)
                _InlineChipStat(
                  icon: LucideIcons.shieldCheck,
                  label:
                      '${l10n.budgetCommittedBaseline}: ${overview.committedBaselineDisplay}',
                ),
            ],
          ),
          SizedBox(height: spacing.md),
          const FeatherDivider(),
          SizedBox(height: spacing.sm),
          Text(
            overview.hasUnbudgetedSpend
                ? l10n.budgetAllExpensesLine(
                    overview.allExpenseActualDisplay,
                    overview.unbudgetedActualDisplay,
                  )
                : l10n.budgetAllExpensesOnly(overview.allExpenseActualDisplay),
            style: AppTypography.meta(context),
          ),
          if (overview.hasLeftoverPendingInReview) ...[
            SizedBox(height: spacing.xs),
            Text(
              l10n.budgetLeftoverPendingHint,
              style: AppTypography.meta(context)
                  .copyWith(color: context.colors.frequency),
            ),
          ],
          if (overview.hasHighFrequencyMaterializationHint) ...[
            SizedBox(height: spacing.xs),
            Text(
              l10n.budgetMaterializedOnlyHint,
              style: AppTypography.meta(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment crossAxisAlignment;

  const _MetricColumn({
    required this.label,
    required this.value,
    required this.color,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
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

class _InlineChipStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineChipStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: AppTypography.meta(context))),
      ],
    );
  }
}
