import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
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
import 'budget_edit_sheet.dart';
import 'budget_trend_chart.dart';

Future<void> showBudgetDrilldownSheet(
  BuildContext context, {
  required YearMonth month,
  required String categoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (_) => BudgetDrilldownSheet(
      month: month,
      categoryId: categoryId,
    ),
  );
}

class BudgetDrilldownSheet extends ConsumerStatefulWidget {
  final YearMonth month;
  final String categoryId;

  const BudgetDrilldownSheet({
    super.key,
    required this.month,
    required this.categoryId,
  });

  @override
  ConsumerState<BudgetDrilldownSheet> createState() =>
      _BudgetDrilldownSheetState();
}

class _BudgetDrilldownSheetState extends ConsumerState<BudgetDrilldownSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _noteInitialized = false;
  bool _savingNote = false;

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

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
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
            return const SizedBox.shrink();
          }

          if (!_noteInitialized) {
            _noteController.text = row.reviewNote ?? '';
            _noteInitialized = true;
          }

          return Column(
            children: [
              const AppSheetHandle(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.md),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: const Icon(LucideIcons.x),
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
                      AppButton.secondary(
                        onPressed: () => showBudgetEditSheet(
                          context,
                          row: row,
                          currencyCode: currencyCode,
                          currencySymbol: currencySymbol,
                          month: widget.month,
                          isHistoricalMonth: widget.month < nowYm,
                        ),
                        child: Text(
                          row.budgetMinor != null
                              ? l10n.edit
                              : l10n.budgetSetButton,
                        ),
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
                    spacing.xl + MediaQuery.of(context).viewInsets.bottom,
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
                      child: Row(children: [
                        Expanded(
                            child: Text(l10n.budgetTopTransactionsTitle,
                                style: AppTypography.sectionTitle(context))),
                        if (row.allContributions.length > 3)
                          AppButton.text(
                            onPressed: () => Navigator.of(context,
                                    rootNavigator: true)
                                .push(MaterialPageRoute<void>(
                                    builder: (_) => _BudgetContributionsPage(
                                        month: widget.month,
                                        categoryId: widget.categoryId))),
                            child: Text(l10n.budgetViewAll),
                          ),
                      ]),
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
                    SizedBox(height: spacing.md),
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
                                AppButton(
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
      ),
    );
  }
}

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
