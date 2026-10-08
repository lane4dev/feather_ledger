import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:feather_ledger/app/design_system/app_floating_toolbar.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';

import '../../domain/services/budget_service.dart';
import '../../domain/entities/budget_entities.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_ui_mapper.dart';
import '../models/budget_ui_models.dart';
import '../view_model/budget_view_model.dart';
import '../widgets/budget_attribution_card.dart';
import '../widgets/budget_category_section.dart';
import 'budget_category_detail_screen.dart';
import '../widgets/budget_edit_sheet.dart';
import '../widgets/budget_overview_card.dart';
import '../widgets/budget_trend_chart.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  bool _toolbarVisible = true;
  late final PageController _pageController;

  int _index(DateTime date) => (date.year - 2000) * 12 + date.month - 1;
  DateTime _date(int index) => DateTime(2000, index + 1);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
        initialPage: _index(
            ref.read(budgetViewModelProvider).selectedMonth.toDateTime()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changeMonth(DateTime date) {
    final target = _index(date);
    if (!_pageController.hasClients || target < 0) return;
    if ((_pageController.page!.round() - target).abs() > 1 ||
        MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(target);
    } else {
      _pageController.animateToPage(target,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        notification is! UserScrollNotification) return false;
    final visible = switch (notification.direction) {
      ScrollDirection.forward => true,
      ScrollDirection.reverse => false,
      ScrollDirection.idle =>
        notification.metrics.pixels <= notification.metrics.minScrollExtent ||
            _toolbarVisible,
    };
    if (visible != _toolbarVisible) setState(() => _toolbarVisible = visible);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final uiState = ref.watch(budgetViewModelProvider);
    ref.listen(budgetViewModelProvider, (previous, next) {
      if (previous?.selectedMonth != next.selectedMonth) {
        if (!_toolbarVisible) setState(() => _toolbarVisible = true);
        final target = _index(next.selectedMonth.toDateTime());
        if (_pageController.hasClients &&
            target >= 0 &&
            _pageController.page?.round() != target) {
          _pageController.jumpToPage(target);
        }
      }
    });
    final selectedDate = uiState.selectedMonth.toDateTime();
    final nowYm = YearMonth.fromDate(ref.read(budgetClockProvider).now());
    final currencyCode = ref.watch(ledgerCurrencyProvider);
    final currencySymbol = ref.watch(displayCurrencySymbolProvider);
    final summaryAsync =
        ref.watch(budgetMonthSummaryProvider(uiState.selectedMonth));

    final notifier = ref.read(budgetViewModelProvider.notifier);
    final summary = summaryAsync.asData?.value;
    final showToolbar = summary != null &&
        summary.hasAnyActiveAccount &&
        summary.mode == BudgetMode.track;
    final visible =
        _toolbarVisible || MediaQuery.accessibleNavigationOf(context);
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: showToolbar
          ? ExcludeSemantics(
              excluding: !visible,
              child: IgnorePointer(
                ignoring: !visible,
                child: AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 1.5),
                  duration: animationDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: animationDuration,
                    child: AppFloatingToolbar(
                      child: AppChoiceChips<bool>.floating(
                        choices: [
                          ButtonSegment(
                            value: false,
                            label: Text(l10n.budgetTracking),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(l10n.budgetReviewPreviewToggle),
                          ),
                        ],
                        selected: uiState.isReviewPreview,
                        onSelected: (selection) {
                          if (selection != uiState.isReviewPreview) {
                            notifier.toggleReviewPreview();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: LedgerMonthSwitcher(
          selectedDate: selectedDate,
          onChanged: _changeMonth,
          onTap: () {
            FeatherMonthPicker.show(
              context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onMonthSelected: _changeMonth,
            );
          },
        ),
        actions: [
          if (summaryAsync.asData?.value != null)
            Builder(
              builder: (context) {
                final model = const BudgetUiMapper().mapScreen(
                  summaryAsync.asData!.value,
                  currencySymbol: currencySymbol,
                  locale: locale,
                );
                if (!model.overview.hasAnyAccount ||
                    model.allEditableCategories.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AppIconButton(
                  icon: const Icon(LucideIcons.plus),
                  tooltip: l10n.budgetSetButton,
                  onPressed: () => _pickCategoryToEdit(
                    context,
                    model: model,
                    currencyCode: currencyCode,
                    currencySymbol: currencySymbol,
                    month: uiState.selectedMonth,
                    isHistoricalMonth: uiState.selectedMonth < nowYm,
                  ),
                );
              },
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => notifier.setMonth(_date(index)),
        itemBuilder: (context, index) {
          final month = YearMonth.fromDate(_date(index));
          return Consumer(builder: (context, ref, _) {
            final monthSummary = ref.watch(budgetMonthSummaryProvider(month));
            return _buildMonth(
                context,
                monthSummary,
                uiState.copyWith(selectedMonth: month),
                currencyCode,
                currencySymbol,
                locale,
                nowYm);
          });
        },
      ),
    );
  }

  Widget _buildMonth(
    BuildContext context,
    AsyncValue<MonthBudgetSummary> summaryAsync,
    BudgetUiState uiState,
    String currencyCode,
    String currencySymbol,
    String locale,
    YearMonth nowYm,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(budgetViewModelProvider.notifier);
    final summary = summaryAsync.asData?.value;
    final showToolbar = summary != null &&
        summary.hasAnyActiveAccount &&
        summary.mode == BudgetMode.track;
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString())),
      data: (summary) {
        final model = const BudgetUiMapper().mapScreen(
          summary,
          currencySymbol: currencySymbol,
          locale: locale,
        );
        final overview = model.overview;

        if (!overview.hasAnyAccount) {
          return Center(
            child: Padding(
              padding: context.pagePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.wallet,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(
                    l10n.budgetEmptyNoAccountsTitle,
                    style: AppTypography.sectionTitle(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(
                    l10n.budgetEmptyNoAccountsBody(overview.currencyCode),
                    style: AppTypography.meta(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacing.lg),
                  AppButton(
                    onPressed: () => context.push('/accounts_management'),
                    child: Text(l10n.manageAccounts),
                  ),
                ],
              ),
            ),
          );
        }

        final showAttribution = overview.mode == BudgetMode.review ||
            (overview.mode == BudgetMode.track && uiState.isReviewPreview);

        return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView(
              key: PageStorageKey(uiState.selectedMonth),
              padding: context.pagePadding.add(
                EdgeInsets.symmetric(vertical: context.spacing.md),
              ),
              children: [
                BudgetOverviewCard(
                  overview: overview,
                ),
                if (!overview.hasAnyBudget) ...[
                  SizedBox(height: context.spacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.budgetEmptyNoBudgetsTitle,
                          style: AppTypography.sectionTitle(context),
                        ),
                        SizedBox(height: context.spacing.xs),
                        Text(
                          l10n.budgetEmptyNoBudgetsBody,
                          style: AppTypography.meta(context),
                        ),
                      ],
                    ),
                  ),
                ],
                if (showAttribution) ...[
                  SizedBox(height: context.spacing.md),
                  BudgetAttributionCard(
                    overBudgetTop3: model.overBudgetTop3,
                    underBudgetTop3: model.underBudgetTop3,
                    unbudgetedAlertsTop3: model.unbudgetedAlertsTop3,
                    monthReviewNote: model.monthReviewNote,
                    onCategoryTap: (categoryId) => showBudgetCategoryDetail(
                      context,
                      month: uiState.selectedMonth,
                      categoryId: categoryId,
                    ),
                    onSaveMonthNote: (note) async {
                      final result = await notifier.saveReviewNote(
                        currencyCode: currencyCode,
                        month: uiState.selectedMonth,
                        note: note,
                      );
                      if (!context.mounted) return;
                      switch (result) {
                        case Success():
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.budgetNoteSaved)),
                          );
                        case Failure(:final code):
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(code.message(l10n))),
                          );
                      }
                    },
                  ),
                ],
                if (overview.hasAnyBudget ||
                    summary.allExpenseActualMinor > 0) ...[
                  SizedBox(height: context.spacing.md),
                  BudgetTrendChart(points: model.monthTrend6Months),
                ],
                SizedBox(height: context.spacing.lg),
                BudgetCategorySection(
                  budgetedRows: model.budgetedRows,
                  unbudgetedActiveRows: model.unbudgetedActiveRows,
                  remainingActiveRows: model.remainingActiveRows,
                  showRemaining: uiState.showRemainingCategories,
                  onToggleRemaining: notifier.toggleRemainingCategories,
                  onRowTap: (row) => showBudgetCategoryDetail(
                    context,
                    month: uiState.selectedMonth,
                    categoryId: row.categoryId,
                  ),
                  onSetBudgetTap: (row) => showBudgetEditSheet(
                    context,
                    row: row,
                    currencyCode: currencyCode,
                    currencySymbol: currencySymbol,
                    month: uiState.selectedMonth,
                    isHistoricalMonth: uiState.selectedMonth < nowYm,
                  ),
                ),
                SizedBox(height: context.spacing.xl),
                if (showToolbar)
                  SizedBox(
                    height: context.metrics.controlHeight +
                        context.spacing.lg * 2 +
                        MediaQuery.textScalerOf(context).scale(20) * 2,
                  ),
              ],
            ));
      },
    );
  }

  Future<void> _pickCategoryToEdit(
    BuildContext context, {
    required BudgetScreenUiModel model,
    required String currencyCode,
    required String currencySymbol,
    required YearMonth month,
    required bool isHistoricalMonth,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final categories = model.allEditableCategories;
    final picked = await showModalBottomSheet<BudgetCategoryRowUiModel>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSheetHandle(),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: sheetContext.spacing.lg),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.budgetPickCategoryTitle,
                  style: AppTypography.sectionTitle(sheetContext),
                ),
              ),
            ),
            SizedBox(height: sheetContext.spacing.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const FeatherDivider(),
                itemBuilder: (ctx, i) {
                  final row = categories[i];
                  return ListTile(
                    onTap: () => Navigator.of(sheetContext).pop(row),
                    leading: AppIconBadge(
                      color: Color(row.colorInt),
                      child: CategoryIcon(
                        iconKey: row.iconKey,
                        size: ctx.metrics.iconSize,
                        color: Color(row.colorInt),
                      ),
                    ),
                    title: Text(row.name),
                    trailing: row.budgetDisplay != null
                        ? Text(
                            row.budgetDisplay!,
                            style: AppTypography.amount(ctx),
                          )
                        : Text(
                            l10n.budgetSetButton,
                            style: AppTypography.meta(ctx),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await showBudgetEditSheet(
        context,
        row: picked,
        currencyCode: currencyCode,
        currencySymbol: currencySymbol,
        month: month,
        isHistoricalMonth: isHistoricalMonth,
      );
    }
  }
}
