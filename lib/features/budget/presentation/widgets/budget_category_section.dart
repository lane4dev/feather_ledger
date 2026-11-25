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

/// The category lists of the budget screen: every budgeted category, then the
/// categories that spent without a limit, then the untouched ones behind a
/// toggle.
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
    // Every row of the group carries the same header model, so the total
    // above the rows is derived from those rows and cannot contradict them.
    final unbudgetedGroup =
        unbudgetedActiveRows.isEmpty ? null : unbudgetedActiveRows.first
            .unbudgetedGroup;

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
                    // A plan row has nothing to read: the tap belongs to the
                    // editor. An archived row is not editable, so it falls
                    // back to the read-only detail.
                    onTap: () =>
                        budgetedRows[i].mode == BudgetMode.plan &&
                                budgetedRows[i].isBudgetEditable
                            ? onSetBudgetTap(budgetedRows[i])
                            : onRowTap(budgetedRows[i]),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
        ],
        if (unbudgetedActiveRows.isNotEmpty) ...[
          _SectionHeader(
            title: l10n.budgetSectionUnbudgetedActive,
            trailing: unbudgetedGroup == null
                ? null
                : unbudgetedGroup.isPendingOnly
                    ? l10n.budgetRowPending(unbudgetedGroup.amountDisplay)
                    : l10n.budgetRowGroupSpent(unbudgetedGroup.amountDisplay),
          ),
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

  /// The group's own total, phrased by the caller.
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(title, style: AppTypography.sectionTitle(context)),
          ),
          if (trailing != null) ...[
            SizedBox(width: context.spacing.sm),
            Flexible(
              child: Text(
                trailing,
                textAlign: TextAlign.end,
                style: AppTypography.compactAmount(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The 40dp tonal disc that stands in front of a category's name.
class _CategoryAvatar extends StatelessWidget {
  final BudgetCategoryRowUiModel row;

  static const double _size = 40;

  const _CategoryAvatar({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(row.colorInt);
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(scheme.surfaceContainerLow, color, 0.14),
      ),
      alignment: Alignment.center,
      child: CategoryIcon(
        iconKey: row.iconKey,
        size: context.metrics.iconSize,
        color: color,
      ),
    );
  }
}

/// The middle anchor: name, an opt-in badge row, and one line of context.
///
/// Nothing here is allowed to ellipsize — a name that does not fit wraps, and
/// the row grows to hold it.
class _CategoryText extends StatelessWidget {
  final BudgetCategoryRowUiModel row;

  const _CategoryText({required this.row});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final subtitle = _subtitleText(l10n, row);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(row.name, style: Theme.of(context).textTheme.bodyLarge),
            if (row.isAnomaly)
              Semantics(
                container: true,
                label: l10n.budgetRowAnomalySemantics,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.expense,
                  ),
                ),
              ),
            if (row.archived) AppBadge(label: l10n.budgetArchivedReadOnly),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: spacing.xs),
          Text(subtitle, style: AppTypography.meta(context)),
        ],
      ],
    );
  }
}

/// The right anchor: what the amount measures, the amount, and — when the row
/// compares against a limit — the spend that produced it.
class _RowAmounts extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final TextAlign textAlign;

  const _RowAmounts({required this.row, required this.textAlign});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = _mainAmountText(l10n, row);
    if (amount == null) return const SizedBox.shrink();

    final color = row.isMainAmountNegative ? context.colors.expense : null;
    return Column(
      crossAxisAlignment: textAlign == TextAlign.end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: textAlign == TextAlign.end
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(
            amount,
            textAlign: textAlign,
            style: AppTypography.amount(context).copyWith(
              fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              color: color,
            ),
          ),
        ),
        if (row.secondaryAmountDisplay != null)
          Text(
            row.secondaryAmountDisplay!,
            textAlign: textAlign,
            style: AppTypography.meta(context),
          ),
      ],
    );
  }
}

/// The four-dp bar: spent, then billed, capped at the track's width so an
/// overrun reads as a full bar and the number above carries the excess.
class _CategoryBar extends StatelessWidget {
  final BudgetCategoryRowUiModel row;

  static const double _height = 4;

  const _CategoryBar({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPlan = row.mode == BudgetMode.plan;
    final actualColor = switch (row.riskLevel) {
      BudgetRiskLevel.overBudget => context.colors.expense,
      BudgetRiskLevel.atRisk ||
      BudgetRiskLevel.inBudget ||
      BudgetRiskLevel.none =>
        scheme.primary,
    };

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                key: ValueKey('budget-category-bar-${row.categoryId}'),
                color: scheme.surfaceContainerHighest,
              ),
              if (isPlan)
                Positioned(
                  left: 0,
                  width: width * row.baselineProgress,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    key: ValueKey('budget-category-bar-baseline-${row.categoryId}'),
                    color: context.colors.frequency.withValues(alpha: 0.5),
                  ),
                )
              else ...[
                if (row.actualProgress > 0)
                  Positioned(
                    left: 0,
                    width: width * row.actualProgress,
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(
                      key: ValueKey(
                        'budget-category-bar-actual-${row.categoryId}',
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
                      key: ValueKey(
                        'budget-category-bar-pending-${row.categoryId}',
                      ),
                      color: context.colors.frequency.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Below this content width — or under large text — the amount block moves
/// under the name instead of competing with it.
const double _stackedLayoutWidth = 300;

/// Wide enough for "Projected over ¥1,200.00"-scale labels before the
/// FittedBox starts shrinking them.
const double _amountBlockMaxWidth = 132;

class _BudgetedCategoryRow extends StatelessWidget {
  final BudgetCategoryRowUiModel row;
  final VoidCallback onTap;

  const _BudgetedCategoryRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final showBar = row.mode == BudgetMode.plan
        ? row.baselineProgress > 0
        : row.actualProgress > 0 || row.pendingProgress > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.metrics.compactGutter,
          vertical: context.metrics.rowInset,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < _stackedLayoutWidth ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;

            final header = stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CategoryAvatar(row: row),
                          SizedBox(width: spacing.sm),
                          Expanded(child: _CategoryText(row: row)),
                        ],
                      ),
                      SizedBox(height: spacing.xs),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 40 + spacing.sm,
                        ),
                        child: _RowAmounts(row: row, textAlign: TextAlign.start),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _CategoryAvatar(row: row),
                      SizedBox(width: spacing.sm),
                      Expanded(child: _CategoryText(row: row)),
                      SizedBox(width: spacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _amountBlockMaxWidth,
                        ),
                        child: _RowAmounts(row: row, textAlign: TextAlign.end),
                      ),
                    ],
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (showBar) ...[
                  SizedBox(height: spacing.sm),
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: 40 + spacing.sm),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: _CategoryBar(row: row),
                    ),
                  ),
                ],
              ],
            );
          },
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
    final spacing = context.spacing;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.metrics.compactGutter,
          vertical: context.metrics.rowInset,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < _stackedLayoutWidth ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final action = row.isBudgetEditable
                ? _SetBudgetAction(onPressed: onSetBudgetTap)
                : null;

            final header = stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CategoryAvatar(row: row),
                          SizedBox(width: spacing.sm),
                          Expanded(child: _CategoryText(row: row)),
                        ],
                      ),
                      SizedBox(height: spacing.xs),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 40 + spacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RowAmounts(row: row, textAlign: TextAlign.start),
                            if (action != null) action,
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _CategoryAvatar(row: row),
                      SizedBox(width: spacing.sm),
                      Expanded(child: _CategoryText(row: row)),
                      SizedBox(width: spacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _amountBlockMaxWidth,
                        ),
                        child: _RowAmounts(row: row, textAlign: TextAlign.end),
                      ),
                      if (action != null) ...[
                        SizedBox(width: spacing.xs),
                        action,
                      ],
                    ],
                  );

            return header;
          },
        ),
      ),
    );
  }
}

/// "Set budget" for a category that has spent without one — a quiet action,
/// not a call to action, so the amount keeps the row's emphasis.
class _SetBudgetAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _SetBudgetAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        l10n.budgetSetButton,
        style: AppTypography.compactAmount(context),
      ),
    );
  }
}

String? _mainAmountText(AppLocalizations l10n, BudgetCategoryRowUiModel row) {
  final amount = row.mainAmountDisplay;
  if (amount == null) return null;
  return switch (row.amountLabel) {
    BudgetCategoryAmountLabel.none => amount,
    BudgetCategoryAmountLabel.remaining => l10n.budgetRowRemaining(amount),
    BudgetCategoryAmountLabel.projectedOver =>
      l10n.budgetRowProjectedOver(amount),
    BudgetCategoryAmountLabel.over => l10n.budgetRowOver(amount),
    BudgetCategoryAmountLabel.reviewRemaining =>
      l10n.budgetRowReviewRemaining(amount),
    BudgetCategoryAmountLabel.reviewOver => l10n.budgetRowReviewOver(amount),
    BudgetCategoryAmountLabel.planBudget => l10n.budgetRowPlanBudget(amount),
  };
}

/// The row's one line of context: why the row is worth reading, plus — for a
/// category without a limit — its share of the month's spending.
String? _subtitleText(AppLocalizations l10n, BudgetCategoryRowUiModel row) {
  final kind = switch (row.subtitleKind) {
    BudgetCategorySubtitle.none => null,
    BudgetCategorySubtitle.pendingIncluded =>
      l10n.budgetRowPendingIncluded(row.subtitleAmountDisplay!),
    BudgetCategorySubtitle.pending =>
      l10n.budgetRowPending(row.subtitleAmountDisplay!),
    BudgetCategorySubtitle.usage =>
      l10n.budgetRowUsage(row.subtitlePercentDisplay!),
    BudgetCategorySubtitle.baseline => row.subtitleReferenceDisplay == null
        ? l10n.budgetRowBaseline(row.subtitleAmountDisplay!)
        : '${l10n.budgetRowBaseline(row.subtitleAmountDisplay!)} · '
            '${l10n.budgetThreeMoAvgRef(row.subtitleReferenceDisplay!)}',
  };
  final share = row.sharePercentDisplay;
  return [
    if (share != null) l10n.budgetRowShare(share),
    if (kind != null) kind,
  ].join(' · ').ifEmptyNull();
}

extension on String {
  String? ifEmptyNull() => isEmpty ? null : this;
}
