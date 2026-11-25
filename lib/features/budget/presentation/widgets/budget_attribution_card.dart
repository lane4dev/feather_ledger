import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../models/budget_ui_models.dart';

/// Month review attribution: over/under budget TOP 3 and the month note.
///
/// The over and under lists sit side by side when the card is wide enough and
/// stack when it is not, so a narrow screen or large text never forces the
/// category names into a sliver. Order comes from the domain lists unchanged.
///
/// The note editor only renders when [onSaveMonthNote] is provided. The L2
/// review page owns its own editor (it needs the save result to keep the draft
/// on failure), so it passes no callback here.
class BudgetAttributionCard extends StatefulWidget {
  final List<BudgetAttributionItemUiModel> overBudgetTop3;
  final List<BudgetAttributionItemUiModel> underBudgetTop3;
  final List<BudgetUnbudgetedAlertUiModel> unbudgetedAlertsTop3;
  final String? monthReviewNote;
  final ValueChanged<String> onCategoryTap;
  final Future<void> Function(String note)? onSaveMonthNote;

  const BudgetAttributionCard({
    super.key,
    required this.overBudgetTop3,
    required this.underBudgetTop3,
    this.unbudgetedAlertsTop3 = const [],
    this.monthReviewNote,
    required this.onCategoryTap,
    this.onSaveMonthNote,
  });

  @override
  State<BudgetAttributionCard> createState() => _BudgetAttributionCardState();
}

class _BudgetAttributionCardState extends State<BudgetAttributionCard> {
  bool _editingNote = false;
  late final TextEditingController _noteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.monthReviewNote ?? '');
  }

  @override
  void didUpdateWidget(covariant BudgetAttributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingNote && oldWidget.monthReviewNote != widget.monthReviewNote) {
      _noteController.text = widget.monthReviewNote ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    setState(() => _saving = true);
    await widget.onSaveMonthNote!(_noteController.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editingNote = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final showOver = widget.overBudgetTop3.isNotEmpty;
    final showUnder = widget.underBudgetTop3.isNotEmpty;

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
                      items: widget.overBudgetTop3,
                      trailingText: (item) => '+${item.deltaDisplay}',
                      trailingColor: context.colors.expense,
                      onCategoryTap: widget.onCategoryTap,
                    ),
                  if (showUnder)
                    _AttributionColumn(
                      title: l10n.budgetUnderTopTitle,
                      items: widget.underBudgetTop3,
                      trailingText: (item) => item.deltaDisplay,
                      trailingColor: context.colors.income,
                      onCategoryTap: widget.onCategoryTap,
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
          if (widget.unbudgetedAlertsTop3.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Text(
              l10n.budgetUnbudgetedAlertsTitle,
              style: AppTypography.meta(context),
            ),
            SizedBox(height: spacing.xs),
            for (final alert in widget.unbudgetedAlertsTop3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppBadge(label: alert.shareDisplay),
                    SizedBox(width: spacing.sm),
                    Text(
                      alert.actualDisplay,
                      style: AppTypography.amount(context)
                          .copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
          ],
          if (widget.onSaveMonthNote != null) ...[
            SizedBox(height: spacing.md),
            const FeatherDivider(),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Text(
                  l10n.budgetMonthNoteLabel,
                  style: AppTypography.meta(context),
                ),
                const Spacer(),
                if (!_editingNote)
                  TextButton.icon(
                    onPressed: () {
                      _noteController.text = widget.monthReviewNote ?? '';
                      setState(() => _editingNote = true);
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: Text(
                      l10n.edit,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
              ],
            ),
            if (_editingNote) ...[
              SizedBox(height: spacing.xs),
              AppTextField(
                controller: _noteController,
                maxLines: 3,
                minLines: 2,
                hintText: l10n.budgetNotePlaceholder,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: spacing.xs),
              Row(
                children: [
                  Text(
                    l10n.budgetNoteCharCount(_noteController.text.runes.length),
                    style: AppTypography.compactLabel(context).copyWith(
                      color: _noteController.text.runes.length > 500
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AppButton.text(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _editingNote = false),
                    child: Text(l10n.cancel),
                  ),
                  SizedBox(width: spacing.xs),
                  AppButton.outlined(
                    onPressed: _saving ? null : _submitNote,
                    child: Text(l10n.budgetSaveNote),
                  ),
                ],
              ),
            ] else if (widget.monthReviewNote != null) ...[
              SizedBox(height: spacing.xs),
              Text(
                widget.monthReviewNote!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              SizedBox(height: spacing.xs),
              Text(
                l10n.budgetNotePlaceholder,
                style: AppTypography.meta(context),
              ),
            ],
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
