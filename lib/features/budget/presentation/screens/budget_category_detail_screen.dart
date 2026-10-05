import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/transaction_result_card.dart';

import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_ui_mapper.dart';
import '../models/budget_ui_models.dart';
import '../view_model/budget_view_model.dart';
import '../widgets/budget_edit_sheet.dart';
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
  final TextEditingController _noteController = TextEditingController();
  bool _noteInitialized = false;
  bool _savingNote = false;
  bool _clearingBudget = false;

  Future<void> _clearBudget(String currencyCode) async {
    if (_clearingBudget) return;
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
    var scope = BudgetEditScope.thisAndFollowing;
    final selectedScope = await showDialog<BudgetEditScope>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.budgetClearConfirmTitle),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                Text(l10n.budgetScopeFutureOverrideWarning,
                    style: AppTypography.compactLabel(context)
                        .copyWith(color: context.colors.expense)),
              ],
            ]),
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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote(String currencyCode) async {
    setState(() => _savingNote = true);
    final result =
        await ref.read(budgetViewModelProvider.notifier).saveReviewNote(
              currencyCode: currencyCode,
              month: widget.month,
              categoryId: widget.categoryId,
              note: _noteController.text,
            );
    if (!mounted) return;
    setState(() => _savingNote = false);

    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.budgetNoteSaved)));
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
    final summaryAsync = ref.watch(budgetMonthSummaryProvider(widget.month));
    final nowYm = YearMonth.fromDate(ref.read(budgetClockProvider).now());
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
          child: summaryAsync.when(
        loading: () => _statusPage(const CircularProgressIndicator()),
        error: (err, _) => _statusPage(Text(l10n.errorPrefix(err.toString()))),
        data: (summary) {
          final screenModel = const BudgetUiMapper().mapScreen(
            summary,
            currencySymbol: currencySymbol,
            locale: locale,
          );
          final allRows = [
            ...screenModel.budgetedRows,
            ...screenModel.unbudgetedActiveRows,
            ...screenModel.remainingActiveRows,
          ];
          final row = allRows
              .where((r) => r.categoryId == widget.categoryId)
              .firstOrNull;
          if (row == null) {
            return _statusPage(const SizedBox.shrink());
          }

          if (!_noteInitialized) {
            _noteController.text = row.reviewNote ?? '';
            _noteInitialized = true;
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.md),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(width: spacing.xs),
                    AppIconBadge(
                      color: Color(row.colorInt),
                      child: CategoryIcon(
                        iconKey: row.iconKey,
                        size: context.metrics.iconSize,
                        color: Color(row.colorInt),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Row(
                        children: [
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
                    ),
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
                                  isHistoricalMonth: widget.month < nowYm);
                            case _BudgetAction.clear:
                              _clearBudget(currencyCode);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: _BudgetAction.edit,
                              child: Text(l10n.edit)),
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
              ),
              SizedBox(height: spacing.sm),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    spacing.md,
                    spacing.xs,
                    spacing.md,
                    spacing.xl,
                  ),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _KvMetric(
                                  label: l10n.budgetTotal,
                                  value: row.budgetDisplay ?? '—',
                                ),
                              ),
                              Expanded(
                                child: _KvMetric(
                                  label: l10n.budgetActualSpent,
                                  value: row.actualDisplay,
                                ),
                              ),
                              if (row.pendingDisplay != null)
                                Expanded(
                                  child: _KvMetric(
                                    label: l10n.budgetPendingShort,
                                    value: row.pendingDisplay!,
                                    color: context.colors.frequency,
                                  ),
                                ),
                            ],
                          ),
                          if (row.lastMonthActualDisplay != null ||
                              row.threeMonthAvgDisplay != null) ...[
                            SizedBox(height: spacing.md),
                            const FeatherDivider(),
                            SizedBox(height: spacing.sm),
                            Wrap(
                              spacing: spacing.md,
                              runSpacing: spacing.xs,
                              children: [
                                if (row.lastMonthActualDisplay != null)
                                  Text(
                                    l10n.budgetLastMonthRef(
                                        row.lastMonthActualDisplay!),
                                    style: AppTypography.meta(context),
                                  ),
                                if (row.threeMonthAvgDisplay != null)
                                  Text(
                                    l10n.budgetThreeMoAvgRef(
                                        row.threeMonthAvgDisplay!),
                                    style: AppTypography.meta(context),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    BudgetTrendChart(
                      points: row.trend6Months,
                      threeMonthAvgChartValue: row.threeMonthAvgMinor != null
                          ? row.threeMonthAvgMinor! / 100.0
                          : null,
                    ),
                    SizedBox(height: spacing.md),
                    AppCard(
                      child: Row(
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
                          Expanded(
                            child: _KvMetric(
                              label: l10n.budgetCommittedBaseline,
                              value: row.committedBaselineDisplay,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing.xs),
                      child: Text(l10n.budgetTopTransactionsTitle,
                          style: AppTypography.sectionTitle(context)),
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
                      Column(children: [
                        for (var i = 0;
                            i < row.topContributions.length;
                            i++) ...[
                          if (i > 0) SizedBox(height: spacing.sm),
                          _ContributionCard(
                              transaction: row.topContributions[i],
                              categoryName: row.name),
                        ],
                      ]),
                    if (row.allContributions.length > 3)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppButton.text(
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
                      ),
                    SizedBox(height: context.metrics.sectionGap),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.budgetCategoryNoteLabel,
                            style: AppTypography.sectionTitle(context),
                          ),
                          SizedBox(height: spacing.sm),
                          if (row.archived) ...[
                            Text(
                              l10n.budgetArchivedNoteHint,
                              style: AppTypography.meta(context),
                            ),
                            if (row.reviewNote != null) ...[
                              SizedBox(height: spacing.sm),
                              Text(
                                row.reviewNote!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ] else ...[
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
                                  l10n.budgetNoteCharCount(
                                    _noteController.text.runes.length,
                                  ),
                                  style: AppTypography.compactLabel(context)
                                      .copyWith(
                                    color:
                                        _noteController.text.runes.length > 500
                                            ? scheme.error
                                            : scheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                AppButton.outlined(
                                  onPressed: _savingNote
                                      ? null
                                      : () => _saveNote(currencyCode),
                                  child: Text(l10n.budgetSaveNote),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      )),
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
    return TransactionResultCard(
      title:
          transaction.title.trim().isEmpty ? categoryName : transaction.title,
      metadata: [
        l10n.expense,
        categoryName,
        if (transaction.accountName.isNotEmpty) transaction.accountName
      ].join(' · '),
      date: transaction.dateDisplay,
      amount: '- ${transaction.amountDisplay}',
      amountColor: context.colors.expense,
      badges: [
        AppBadge(
            label: transaction.isCommitted
                ? l10n.budgetCommitted
                : l10n.budgetDiscretionary),
        if (transaction.isPending)
          AppBadge(
              label: l10n.budgetPendingShort, color: context.colors.frequency),
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
    final locale = Localizations.localeOf(context).toString();
    final currency = ref.watch(displayCurrencySymbolProvider);
    final summary = ref.watch(budgetMonthSummaryProvider(month));
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.budgetTopTransactionsTitle),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.errorPrefix(error.toString()))),
        data: (data) {
          final model = const BudgetUiMapper()
              .mapScreen(data, currencySymbol: currency, locale: locale);
          final row = [
            ...model.budgetedRows,
            ...model.unbudgetedActiveRows,
            ...model.remainingActiveRows
          ].where((item) => item.categoryId == categoryId).firstOrNull;
          if (row == null) return const SizedBox.shrink();
          return ListView.separated(
            padding: context.pagePadding
                .add(EdgeInsets.symmetric(vertical: context.spacing.md)),
            itemCount: row.allContributions.isEmpty
                ? 2
                : row.allContributions.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: context.spacing.sm),
            itemBuilder: (context, index) => index == 0
                ? Text(
                    '${row.name} · ${DateFormat.yMMMM(locale).format(month.toDateTime())}',
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
