import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_ui_models.dart';

class BudgetCategorySection extends StatelessWidget {
  final List<BudgetCategoryRowUiModel> budgetedRows;
  final List<BudgetCategoryRowUiModel> unbudgetedActiveRows;
  final List<BudgetCategoryRowUiModel> remainingActiveRows;
  final bool showRemaining;
  final VoidCallback onToggleRemaining;
  final ValueChanged<BudgetCategoryRowUiModel> onRowTap;
  final ValueChanged<BudgetCategoryRowUiModel> onSetBudgetTap;

  const BudgetCategorySection({
    super.key,
    required this.budgetedRows,
    required this.unbudgetedActiveRows,
    required this.remainingActiveRows,
    required this.showRemaining,
    required this.onToggleRemaining,
    required this.onRowTap,
    required this.onSetBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (budgetedRows.isNotEmpty) ...[
          _SectionHeader(title: l10n.budgetSectionBudgeted),
          SizedBox(height: spacing.sm),
          AppCard.group(
            child: Column(
              children: [
                for (var i = 0; i < budgetedRows.length; i++) ...[
                  if (i > 0) const FeatherDivider(),
                  _BudgetedCategoryRow(
                    row: budgetedRows[i],
                    onTap: () => onRowTap(budgetedRows[i]),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
        ],
        if (unbudgetedActiveRows.isNotEmpty) ...[
          _SectionHeader(title: l10n.budgetSectionUnbudgetedActive),
          SizedBox(height: spacing.sm),
          AppCard.group(
            child: Column(
              children: [
                for (var i = 0; i < unbudgetedActiveRows.length; i++) ...[
                  if (i > 0) const FeatherDivider(),
                  _UnbudgetedCategoryRow(
                    row: unbudgetedActiveRows[i],
                    onTap: () => onRowTap(unbudgetedActiveRows[i]),
                    onSetBudgetTap: () =>
                        onSetBudgetTap(unbudgetedActiveRows[i]),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
        ],
        if (remainingActiveRows.isNotEmpty) ...[
          InkWell(
            onTap: onToggleRemaining,
            borderRadius: context.metrics.selectionBorderRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: spacing.sm,
                horizontal: spacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.budgetSectionRemaining} · ${remainingActiveRows.length}',
                      style: AppTypography.meta(context),
                    ),
                  ),
                  Icon(
                    showRemaining
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (showRemaining) ...[
            SizedBox(height: spacing.xs),
            AppCard.group(
              child: Column(
                children: [
                  for (var i = 0; i < remainingActiveRows.length; i++) ...[
                    if (i > 0) const FeatherDivider(),
                    ListTile(
                      onTap: () => onSetBudgetTap(remainingActiveRows[i]),
                      leading: AppIconBadge(
                        color: Color(remainingActiveRows[i].colorInt),
                        child: CategoryIcon(
                          iconKey: remainingActiveRows[i].iconKey,
                          size: context.metrics.iconSize,
                          color: Color(remainingActiveRows[i].colorInt),
                        ),
                      ),
                      title: Text(remainingActiveRows[i].name),
                      trailing: Text(
                        l10n.budgetSetButton,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
      child: Text(title, style: AppTypography.sectionTitle(context)),
    );
  }
}

class _BudgetedCategoryRow extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final VoidCallback onTap;

  const _BudgetedCategoryRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final catColor = Color(row.colorInt);

    final statusBadge = switch (row.riskLevel) {
      BudgetRiskLevel.overBudget => AppBadge(
          label: l10n.budgetStatusOver,
          color: context.colors.expense,
        ),
      BudgetRiskLevel.atRisk => AppBadge(
          label: l10n.budgetStatusAtRisk,
          color: context.colors.frequency,
        ),
      BudgetRiskLevel.inBudget || BudgetRiskLevel.none => null,
    };

    final barColor = switch (row.riskLevel) {
      BudgetRiskLevel.overBudget => context.colors.expense,
      BudgetRiskLevel.atRisk ||
      BudgetRiskLevel.inBudget ||
      BudgetRiskLevel.none =>
        scheme.primary,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.metrics.compactGutter,
          vertical: context.metrics.rowInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconBadge(
                  color: catColor,
                  child: CategoryIcon(
                    iconKey: row.iconKey,
                    size: context.metrics.iconSize,
                    color: catColor,
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: spacing.xs,
                        runSpacing: spacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            row.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (row.archived)
                            AppBadge(label: l10n.budgetArchivedReadOnly),
                          if (statusBadge != null) statusBadge,
                          if (row.isAnomaly && row.anomalyPercent != null)
                            AppBadge(
                              label:
                                  l10n.budgetAnomalyBadge(row.anomalyPercent!),
                              color: context.colors.expense,
                            ),
                        ],
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        row.pendingDisplay != null
                            ? '${l10n.budgetCommitted} ${row.committedActualDisplay} · ${l10n.budgetPendingShort} ${row.pendingDisplay}'
                            : '${l10n.budgetCommitted} ${row.committedActualDisplay} · ${l10n.budgetDiscretionary} ${row.discretionaryActualDisplay}',
                        style: AppTypography.meta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${row.actualDisplay} / ${row.budgetDisplay}',
                      style: AppTypography.amount(context).copyWith(
                        fontSize:
                            Theme.of(context).textTheme.bodyMedium?.fontSize,
                      ),
                    ),
                    if (row.varianceDisplay != null)
                      Text(
                        row.isOverBudget
                            ? '+${row.varianceDisplay}'
                            : row.varianceDisplay!,
                        style: AppTypography.compactLabel(context).copyWith(
                          color: row.isOverBudget
                              ? context.colors.expense
                              : context.colors.income,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 6,
                color: scheme.surfaceContainerHighest,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    return Row(
                      children: [
                        if (row.actualProgress > 0)
                          Container(
                            width: w * row.actualProgress,
                            color: barColor,
                          ),
                        if (row.pendingProgress > 0)
                          Container(
                            width: w * row.pendingProgress,
                            color:
                                context.colors.frequency.withValues(alpha: 0.65),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnbudgetedCategoryRow extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final VoidCallback onTap;
  final VoidCallback onSetBudgetTap;

  const _UnbudgetedCategoryRow({
    required this.row,
    required this.onTap,
    required this.onSetBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catColor = Color(row.colorInt);
    return ListTile(
      onTap: onTap,
      leading: AppIconBadge(
        color: catColor,
        child: CategoryIcon(
          iconKey: row.iconKey,
          size: context.metrics.iconSize,
          color: catColor,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(row.name, overflow: TextOverflow.ellipsis)),
          if (row.archived) ...[
            SizedBox(width: context.spacing.xs),
            AppBadge(label: l10n.budgetArchivedReadOnly),
          ],
        ],
      ),
      subtitle: row.pendingDisplay != null
          ? Text('${l10n.budgetPendingShort} ${row.pendingDisplay}')
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            row.actualDisplay,
            style: AppTypography.amount(context),
          ),
          if (row.isBudgetEditable) ...[
            SizedBox(width: context.spacing.sm),
            TextButton(
              onPressed: onSetBudgetTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
              ),
              child: Text(l10n.budgetSetButton),
            ),
          ],
        ],
      ),
    );
  }
}
