import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';

import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_ui_models.dart';
import '../view_model/budget_view_model.dart';

Future<void> showBudgetEditSheet(
  BuildContext context, {
  required BudgetCategoryRowUiModel row,
  required String currencyCode,
  required String currencySymbol,
  required YearMonth month,
  required bool isHistoricalMonth,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (_) => BudgetEditSheet(
      row: row,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      month: month,
      isHistoricalMonth: isHistoricalMonth,
    ),
  );
}

class BudgetEditSheet extends ConsumerStatefulWidget {
  final BudgetCategoryRowUiModel row;
  final String currencyCode;
  final String currencySymbol;
  final YearMonth month;
  final bool isHistoricalMonth;

  const BudgetEditSheet({
    super.key,
    required this.row,
    required this.currencyCode,
    required this.currencySymbol,
    required this.month,
    required this.isHistoricalMonth,
  });

  @override
  ConsumerState<BudgetEditSheet> createState() => _BudgetEditSheetState();
}

class _BudgetEditSheetState extends ConsumerState<BudgetEditSheet> {
  late final TextEditingController _controller;
  BudgetEditScope _scope = BudgetEditScope.thisAndFollowing;
  bool _hasFutureRules = false;
  bool _loadingFutureCheck = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.row.budgetMinor != null
          ? formatMinor(widget.row.budgetMinor!)
          : '',
    );
    _checkFutureRules();
  }

  Future<void> _checkFutureRules() async {
    final result =
        await ref.read(budgetViewModelProvider.notifier).checkFutureRules(
              currencyCode: widget.currencyCode,
              categoryId: widget.row.categoryId,
              month: widget.month,
            );
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _hasFutureRules = value;
          _loadingFutureCheck = false;
        });
      case Failure(:final code):
        // A failed probe is not a reason to block the sheet: the default scope
        // (this and following) is the safe one, and the save path reports its
        // own failure. Say so rather than throwing out of `initState`.
        setState(() => _loadingFutureCheck = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                code.message(AppLocalizations.of(context)!)),
          ),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _parsedMinor {
    final text = _controller.text.trim();
    if (text.isEmpty || text == '.') return null;
    try {
      return parseMinor(text);
    } on FormatException {
      return null;
    }
  }

  bool get _needsScopePicker =>
      widget.row.budgetMinor != null ||
      _hasFutureRules ||
      widget.isHistoricalMonth;

  Future<void> _save() async {
    final amountMinor = _parsedMinor;
    if (amountMinor == null || amountMinor <= 0) return;

    final effectiveScope =
        _needsScopePicker ? _scope : BudgetEditScope.thisAndFollowing;

    setState(() => _submitting = true);
    final result =
        await ref.read(budgetViewModelProvider.notifier).setCategoryBudget(
              currencyCode: widget.currencyCode,
              categoryId: widget.row.categoryId,
              month: widget.month,
              amountMinor: amountMinor,
              scope: effectiveScope,
            );
    if (!mounted) return;
    setState(() => _submitting = false);

    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.budgetSaved)));
      case Failure(:final code):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(code.message(l10n))));
    }
  }

  void _fillBaseline(int minor) {
    final formatted = formatMinor(minor);
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final amountMinor = _parsedMinor;
    final canSave = amountMinor != null && amountMinor > 0 && !_submitting;
    final isExplicitZero = amountMinor == 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.lg,
        spacing.sm,
        spacing.lg,
        spacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHandle(),
          Row(
            children: [
              AppIconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.of(context).pop(),
              ),
              SizedBox(width: spacing.xs),
              CategoryIcon(
                iconKey: widget.row.iconKey,
                size: context.metrics.iconSize,
                color: Color(widget.row.colorInt),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  '${l10n.budgetEditTitle} · ${widget.row.name}',
                  style: AppTypography.sectionTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.isHistoricalMonth) ...[
            SizedBox(height: spacing.sm),
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: context.metrics.controlBorderRadius,
              ),
              child: Text(
                l10n.budgetHistoryEditHint,
                style: AppTypography.meta(context),
              ),
            ),
          ],
          SizedBox(height: spacing.md),
          Center(
            child: Column(
              children: [
                Text(l10n.budgetAmountLabel,
                    style: AppTypography.meta(context)),
                SizedBox(height: spacing.xs),
                LedgerAmountInput(
                  controller: _controller,
                  type: TransactionKind.expense,
                  currencySymbol: widget.currencySymbol,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
                if (isExplicitZero) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    l10n.budgetZeroAmountHint,
                    style: AppTypography.compactLabel(context)
                        .copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          if (widget.row.lastMonthActualDisplay != null ||
              widget.row.threeMonthAvgDisplay != null ||
              widget.row.committedBaselineMinor > 0) ...[
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.xs,
              alignment: WrapAlignment.center,
              children: [
                if (widget.row.lastMonthActualDisplay != null &&
                    (widget.row.lastMonthActualMinor ?? 0) > 0)
                  ActionChip(
                    label: Text(l10n.budgetLastMonthRef(
                        widget.row.lastMonthActualDisplay!)),
                    onPressed: () =>
                        _fillBaseline(widget.row.lastMonthActualMinor!),
                  ),
                if (widget.row.threeMonthAvgDisplay != null &&
                    (widget.row.threeMonthAvgMinor ?? 0) > 0)
                  ActionChip(
                    label: Text(l10n
                        .budgetThreeMoAvgRef(widget.row.threeMonthAvgDisplay!)),
                    onPressed: () =>
                        _fillBaseline(widget.row.threeMonthAvgMinor!),
                  ),
                if (widget.row.committedBaselineMinor > 0)
                  ActionChip(
                    label: Text(l10n.budgetCommittedRef(
                        widget.row.committedBaselineDisplay)),
                    onPressed: () =>
                        _fillBaseline(widget.row.committedBaselineMinor),
                  ),
              ],
            ),
          ],
          if (!_loadingFutureCheck && _needsScopePicker) ...[
            SizedBox(height: spacing.lg),
            Text(l10n.budgetScopeLabel, style: AppTypography.meta(context)),
            SizedBox(height: spacing.xs),
            AppSegmentedControl<BudgetEditScope>(
              segments: [
                ButtonSegment(
                  value: BudgetEditScope.thisMonthOnly,
                  label: Text(l10n.budgetScopeThisMonth),
                ),
                ButtonSegment(
                  value: BudgetEditScope.thisAndFollowing,
                  label: Text(l10n.budgetScopeThisAndFollowing),
                ),
              ],
              selected: _scope,
              onSelected: (next) => setState(() => _scope = next),
            ),
            if (_hasFutureRules && _scope == BudgetEditScope.thisAndFollowing)
              Padding(
                padding: EdgeInsets.only(top: spacing.xs),
                child: Text(
                  l10n.budgetScopeFutureOverrideWarning,
                  style: AppTypography.compactLabel(context)
                      .copyWith(color: context.colors.expense),
                ),
              ),
          ],
          SizedBox(height: spacing.lg),
          AppButton(
            onPressed: canSave ? _save : null,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
