import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';

import '../models/budget_ui_models.dart';

/// Month review attribution: over/under budget TOP 3.
///
/// The over and under lists sit side by side when the card is wide enough and
/// stack when it is not, so a narrow screen or large text never forces the
/// category names into a sliver. Order comes from the domain lists unchanged.
class BudgetAttributionCard extends StatelessWidget {
  final List<BudgetAttributionItemUiModel> overBudgetTop3;
  final List<BudgetAttributionItemUiModel> underBudgetTop3;
  final ValueChanged<String> onCategoryTap;

  const BudgetAttributionCard({
    super.key,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final showOver = overBudgetTop3.isNotEmpty;
    final showUnder = underBudgetTop3.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: scheme.primary),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  l10n.budgetAttributionTitle,
                  style: AppTypography.sectionTitle(context),
                ),
              ),
            ],
          ),
          if (showOver || showUnder) ...[
            SizedBox(height: spacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(14);
                final sideBySide = constraints.maxWidth >= 300 &&
                    textScale <= 20 &&
                    showOver &&
                    showUnder;
                final columns = <Widget>[
                  if (showOver)
                    _AttributionColumn(
                      title: l10n.budgetOverTopTitle,
                      items: overBudgetTop3,
                      trailingText: (item) => '+${item.deltaDisplay}',
                      trailingColor: context.colors.expense,
                      onCategoryTap: onCategoryTap,
                    ),
                  if (showUnder)
                    _AttributionColumn(
                      title: l10n.budgetUnderTopTitle,
                      items: underBudgetTop3,
                      trailingText: (item) => item.deltaDisplay,
                      trailingColor: context.colors.income,
                      onCategoryTap: onCategoryTap,
                    ),
                ];
                if (!sideBySide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0) SizedBox(height: spacing.sm),
                        columns[i],
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: columns[0]),
                    SizedBox(width: spacing.md),
                    Expanded(child: columns[1]),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AttributionColumn extends StatelessWidget {
  final String title;
  final List<BudgetAttributionItemUiModel> items;
  final String Function(BudgetAttributionItemUiModel item) trailingText;
  final Color trailingColor;
  final ValueChanged<String> onCategoryTap;

  const _AttributionColumn({
    required this.title,
    required this.items,
    required this.trailingText,
    required this.trailingColor,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.meta(context).copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        for (final item in items)
          _AttributionRow(
            categoryId: item.categoryId,
            name: item.name,
            iconKey: item.iconKey,
            colorInt: item.colorInt,
            trailingText: trailingText(item),
            trailingColor: trailingColor,
            onTap: () => onCategoryTap(item.categoryId),
          ),
      ],
    );
  }
}

class _AttributionRow extends StatelessWidget {
  final String categoryId;
  final String name;
  final String iconKey;
  final int colorInt;
  final String trailingText;
  final Color trailingColor;
  final VoidCallback onTap;

  const _AttributionRow({
    required this.categoryId,
    required this.name,
    required this.iconKey,
    required this.colorInt,
    required this.trailingText,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('budget-attribution-$categoryId'),
      onTap: onTap,
      borderRadius: context.metrics.selectionBorderRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
        child: Row(
          children: [
            CategoryIcon(
              iconKey: iconKey,
              size: 16,
              color: Color(colorInt),
            ),
            SizedBox(width: context.spacing.xs),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              trailingText,
              style: AppTypography.amount(context).copyWith(
                color: trailingColor,
                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
