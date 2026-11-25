import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/transaction_list_tile.dart';

import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_ui_models.dart';
import '../view_model/budget_view_model.dart';
import '../widgets/budget_category_detail_sections.dart';
import '../widgets/budget_edit_sheet.dart';
import '../widgets/budget_note_card.dart';
import '../widgets/budget_trend_chart.dart';

Future<void> showBudgetCategoryDetail(
  BuildContext context, {
  required YearMonth month,
  required String categoryId,
}) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/budget/category'),
      transitionDuration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 320),
      reverseTransitionDuration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => BudgetCategoryDetailScreen(
        month: month,
        categoryId: categoryId,
      ),
      transitionsBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class BudgetCategoryDetailScreen extends ConsumerStatefulWidget {
  final YearMonth month;
  final String categoryId;

  const BudgetCategoryDetailScreen({
    super.key,
    required this.month,
    required this.categoryId,
  });

  @override
  ConsumerState<BudgetCategoryDetailScreen> createState() =>
      _BudgetCategoryDetailScreenState();
}

class _BudgetCategoryDetailScreenState
    extends ConsumerState<BudgetCategoryDetailScreen> {
  bool _clearingBudget = false;

  /// Opens the shared note editor for this category. The sheet reports the
  /// saved text, but the card reads the persisted note from the summary
  /// stream — the writer also rewrites it when a budget is cleared.
  Future<void> _editNote(String currencyCode, BudgetCategoryRowUiModel row) {
    return showBudgetNoteSheet(
      context,
      title: AppLocalizations.of(context)!.budgetCategoryNoteLabel,
      contextLabel: row.name,
      initialNote: row.reviewNote,
      onSave: (note) =>
          ref.read(budgetViewModelProvider.notifier).saveReviewNote(
                currencyCode: currencyCode,
                month: widget.month,
                categoryId: widget.categoryId,
                note: note,
              ),
    );
  }

  Future<void> _clearBudget({
    required String currencyCode,
    required BudgetCategoryDetailUiModel detail,
  }) async {
    final row = detail.row;
    if (_clearingBudget) return;
    final budgetDisplay = row.budgetDisplay;
    if (budgetDisplay == null) return;
    setState(() => _clearingBudget = true);
    final futureRules =
        await ref.read(budgetViewModelProvider.notifier).checkFutureRules(
              currencyCode: currencyCode,
              categoryId: widget.categoryId,
              month: widget.month,
            );
    if (!mounted) return;
    if (futureRules case Failure(:final code)) {
      setState(() => _clearingBudget = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(code.message(AppLocalizations.of(context)!))));
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final monthLabel = detail.monthDisplay;
    // Both scopes only ever touch the selected month or later, so "this month
    // only" is the safe default (ADR-0007).
    var scope = BudgetEditScope.thisMonthOnly;
    final selectedScope = await showDialog<BudgetEditScope>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.budgetClearConfirmTitle(row.name)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scope == BudgetEditScope.thisMonthOnly
                      ? l10n.budgetClearConfirmThisMonth(
                          monthLabel, row.name, budgetDisplay)
                      : l10n.budgetClearConfirmThisAndFollowing(
                          monthLabel, row.name, budgetDisplay),
                ),
                SizedBox(height: context.spacing.md),
                AppSegmentedControl<BudgetEditScope>(
                  segments: [
                    ButtonSegment(
                        value: BudgetEditScope.thisMonthOnly,
                        label: Text(l10n.budgetScopeThisMonth)),
                    ButtonSegment(
                        value: BudgetEditScope.thisAndFollowing,
                        label: Text(l10n.budgetScopeThisAndFollowing)),
                  ],
                  selected: scope,
                  onSelected: (value) => setDialogState(() => scope = value),
                ),
                if (futureRules.value &&
                    scope == BudgetEditScope.thisAndFollowing) ...[
                  SizedBox(height: context.spacing.sm),
                  Text(l10n.budgetClearFutureRulesWarning,
                      style: AppTypography.compactLabel(context)
                          .copyWith(color: context.colors.expense)),
                ],
              ],
            ),
          ),
          actions: [
            AppButton.text(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            AppButton.destructive(
              onPressed: () => Navigator.of(dialogContext).pop(scope),
              child: Text(l10n.budgetClearAction),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (selectedScope == null) {
      setState(() => _clearingBudget = false);
      return;
    }
    final result =
        await ref.read(budgetViewModelProvider.notifier).clearCategoryBudget(
              currencyCode: currencyCode,
              categoryId: widget.categoryId,
              month: widget.month,
              scope: selectedScope,
            );
    if (!mounted) return;
    setState(() => _clearingBudget = false);
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.budgetCleared)));
      case Failure(:final code):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(code.message(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final currencyCode = ref.watch(ledgerCurrencyProvider);
    final currencySymbol = ref.watch(displayCurrencySymbolProvider);
    final request = (
      month: widget.month,
      categoryId: widget.categoryId,
      locale: locale,
    );
    final detailAsync = ref.watch(budgetCategoryDetailProvider(request));
    return detailAsync.when(
      loading: () => Scaffold(
          body:
              SafeArea(child: _statusPage(const CircularProgressIndicator()))),
      // The exception is a developer's to read, not the user's: the body is one
      // localized sentence and the cause goes to the log.
      error: (error, _) {
        debugPrint(
            'budget category ${widget.categoryId} failed to load: $error');
        return Scaffold(
          body: SafeArea(
            child: _statusPage(Text(
              l10n.budgetLoadFailedBody,
              style: AppTypography.meta(context),
              textAlign: TextAlign.center,
            )),
          ),
        );
      },
      data: (detail) {
        if (detail == null) {
          return Scaffold(
              body: SafeArea(child: _statusPage(const SizedBox.shrink())));
        }
        final row = detail.row;

        // A closed month has no bills left to arrive: actual only.
        final showPending =
            !detail.isHistoricalMonth && row.pendingDisplay != null;
        final showMaterializationHint = detail.showMaterializationHint;
        final spacing = context.spacing;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            leading: AppIconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                AppIconBadge(
                  color: Color(row.colorInt),
                  child: CategoryIcon(
                    iconKey: row.iconKey,
                    size: context.metrics.iconSize,
                    color: Color(row.colorInt),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Flexible(
                  child: Text(
                    row.name,
                    style: AppTypography.sectionTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (row.archived) ...[
                  SizedBox(width: spacing.xs),
                  AppBadge(label: l10n.budgetArchivedReadOnly),
                ],
              ],
            ),
            actions: [
              if (row.isBudgetEditable)
                PopupMenuButton<_BudgetAction>(
                  enabled: !_clearingBudget,
                  icon: const Icon(LucideIcons.ellipsisVertical),
                  onSelected: (action) {
                    switch (action) {
                      case _BudgetAction.edit:
                        showBudgetEditSheet(context,
                            row: row,
                            currencyCode: currencyCode,
                            currencySymbol: currencySymbol,
                            month: widget.month,
                            isHistoricalMonth: detail.isHistoricalMonth);
                      case _BudgetAction.clear:
                        _clearBudget(
                          currencyCode: currencyCode,
                          detail: detail,
                        );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                        value: _BudgetAction.edit, child: Text(l10n.edit)),
                    PopupMenuItem(
                        value: _BudgetAction.clear,
                        enabled: row.budgetMinor != null,
                        child: Text(l10n.budgetClearAction,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: row.budgetMinor == null
                                        ? scheme.onSurfaceVariant
                                        : scheme.error))),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.md,
                spacing.md,
                spacing.xl,
              ),
              children: [
                BudgetCategoryProgressCard(
                  row: row,
                  showPending: showPending,
                ),
                SizedBox(height: spacing.md),
                BudgetCategoryCompositionCard(
                  row: row,
                  showPending: showPending,
                  showMaterializationHint: showMaterializationHint,
                ),
                if (BudgetTrendChart.shouldShow(row.trend6Months)) ...[
                  SizedBox(height: spacing.md),
                  BudgetTrendChart(
                    points: row.trend6Months,
                    mode: BudgetTrendChartMode.category,
                    threeMonthAvgChartValue: row.threeMonthAvgChartValue,
                  ),
                ],
                SizedBox(height: context.metrics.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: spacing.xs),
                        child: Text(l10n.budgetTopTransactionsTitle,
                            style: AppTypography.sectionTitle(context)),
                      ),
                    ),
                    if (row.allContributions.length > 3)
                      AppButton.text(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => _BudgetContributionsPage(
                                        month: widget.month,
                                        categoryId: widget.categoryId))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.budgetViewAll),
                            SizedBox(width: spacing.xs),
                            Icon(LucideIcons.chevronRight,
                                size: context.metrics.iconSize),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: spacing.sm),
                if (row.topContributions.isEmpty)
                  AppCard(
                    child: Text(
                      l10n.budgetNoTransactionsInMonth,
                      style: AppTypography.meta(context),
                    ),
                  )
                else
                  AppCard.day(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < row.topContributions.length;
                            i++) ...[
                          if (i > 0)
                            FeatherDivider(
                              indent: context.metrics.compactGutter,
                              endIndent: context.metrics.compactGutter,
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          _ContributionCard(
                              transaction: row.topContributions[i],
                              categoryName: row.name),
                        ],
                      ],
                    ),
                  ),
                SizedBox(height: context.metrics.sectionGap),
                BudgetNoteCard(
                  title: l10n.budgetCategoryNoteLabel,
                  note: row.reviewNote,
                  emptyTitle: l10n.budgetCategoryNoteEmptyTitle,
                  emptySubtitle: l10n.budgetNoteEmptySubtitle,
                  readOnlyHint:
                      row.archived ? l10n.budgetArchivedNoteHint : null,
                  onTap:
                      row.archived ? null : () => _editNote(currencyCode, row),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusPage(Widget content) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(child: Center(child: content)),
        ],
      );
}

enum _BudgetAction { edit, clear }

class _ContributionCard extends ConsumerWidget {
  const _ContributionCard(
      {required this.transaction, required this.categoryName});

  final BudgetContributionTxUiModel transaction;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return TransactionListTile(
      title:
          transaction.title.trim().isEmpty ? categoryName : transaction.title,
      accountLabel:
          transaction.accountName.isEmpty ? null : transaction.accountName,
      dateText: transaction.dateDisplay,
      dateFirst: true,
      amount: transaction.amountDisplay,
      amountColor: context.colors.expense,
      showCategoryIcon: false,
      showCategoryName: false,
      trailingTags: [
        AppBadge(
            compact: true,
            label: transaction.isCommitted
                ? l10n.budgetCommitted
                : l10n.budgetDiscretionary),
        if (transaction.isPending)
          AppBadge(
              compact: true,
              label: l10n.budgetPendingShort,
              color: context.colors.frequency),
      ],
      onTap: () async {
        final notifier = ref.read(budgetViewModelProvider.notifier);
        final tile = transaction.isPending
            ? await notifier.loadPendingBillForEdit(transaction.id)
            : await notifier.loadTransactionForEdit(transaction.id);
        if (!context.mounted || tile == null) return;
        await context.push<void>(
            transaction.isPending ? '/ledger/edit-bill' : '/ledger/edit',
            extra: tile);
      },
    );
  }
}

class _BudgetContributionsPage extends ConsumerWidget {
  const _BudgetContributionsPage(
      {required this.month, required this.categoryId});

  final YearMonth month;
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(budgetCategoryDetailProvider((
      month: month,
      categoryId: categoryId,
      locale: Localizations.localeOf(context).toString(),
    )));
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.budgetTopTransactionsTitle),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          debugPrint('budget contributions $categoryId failed: $error');
          return Center(
            child: Padding(
              padding: context.pagePadding,
              child: Text(
                l10n.budgetLoadFailedBody,
                style: AppTypography.meta(context),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (detail) {
          if (detail == null) return const SizedBox.shrink();
          final row = detail.row;
          return ListView.separated(
            padding: context.pagePadding
                .add(EdgeInsets.symmetric(vertical: context.spacing.md)),
            itemCount: row.allContributions.isEmpty
                ? 2
                : row.allContributions.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: context.spacing.sm),
            itemBuilder: (context, index) => index == 0
                ? Text(row.titleDisplay,
                    style: AppTypography.sectionTitle(context))
                : row.allContributions.isEmpty
                    ? Text(l10n.budgetNoTransactionsInMonth,
                        style: AppTypography.meta(context))
                    : _ContributionCard(
                        transaction: row.allContributions[index - 1],
                        categoryName: row.name),
          );
        },
      ),
    );
  }
}
