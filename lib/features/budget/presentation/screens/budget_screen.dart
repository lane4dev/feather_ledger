import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_ui_mapper.dart';
import '../models/budget_home_ui_models.dart';
import '../models/budget_ui_models.dart';
import '../view_model/budget_view_model.dart';
import '../widgets/budget_category_section.dart';
import '../widgets/budget_edit_sheet.dart';
import '../widgets/budget_overview_card.dart';
import 'budget_category_detail_screen.dart';
import 'budget_review_screen.dart';

/// Room under the last item so it can scroll clear of the navigation bar and
/// still be tapped.
const double _bottomReach = 88;

/// The budget home (L1).
///
/// One page per month, composed by the month's phase: a tracked month ends in
/// the review entry, a closed month opens with the review summary bar right
/// under the hero, and a future month ends in the planning hint. Everything
/// else — the hero, the budgeted categories, the unbudgeted spending — is
/// shared. Categories without a budget and without activity left the page for
/// the "+" drawer in the app bar.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final uiState = ref.watch(budgetViewModelProvider);
    ref.listen(budgetViewModelProvider, (previous, next) {
      if (previous?.selectedMonth != next.selectedMonth) {
        final target = _index(next.selectedMonth.toDateTime());
        if (_pageController.hasClients &&
            target >= 0 &&
            _pageController.page?.round() != target) {
          _pageController.jumpToPage(target);
        }
      }
    });
    final selectedMonth = uiState.selectedMonth;
    final selectedDate = selectedMonth.toDateTime();
    final now = ref.read(budgetClockProvider).now();
    final nowYm = YearMonth.fromDate(now);
    final currencyCode = ref.watch(ledgerCurrencyProvider);
    final currencySymbol = ref.watch(displayCurrencySymbolProvider);
    final notifier = ref.read(budgetViewModelProvider.notifier);
    final selectedSummary =
        ref.watch(budgetMonthSummaryProvider(selectedMonth));

    // The "+" drawer is where the untouched categories went: editable, and
    // neither budgeted nor spending. Everywhere else they have no row.
    final selectedSummaryValue = selectedSummary.asData?.value;
    final settableRows = selectedSummaryValue == null
        ? const <BudgetCategoryRowUiModel>[]
        : const BudgetUiMapper()
            .mapScreen(
              selectedSummaryValue,
              currencySymbol: currencySymbol,
              locale: locale,
              today: now,
            )
            .remainingActiveRows
            .where((row) => row.isBudgetEditable)
            .toList();

    return Scaffold(
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
          if (selectedSummaryValue != null &&
              selectedSummaryValue.hasAnyActiveAccount &&
              settableRows.isNotEmpty)
            AppIconButton(
              icon: const Icon(LucideIcons.plus),
              tooltip: l10n.budgetSetButton,
              onPressed: () => _pickCategoryToEdit(
                context,
                rows: settableRows,
                currencyCode: currencyCode,
                currencySymbol: currencySymbol,
                month: selectedMonth,
                isHistoricalMonth: selectedMonth < nowYm,
              ),
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
              month: month,
              currencyCode: currencyCode,
              currencySymbol: currencySymbol,
              locale: locale,
              now: now,
            );
          });
        },
      ),
    );
  }

  Widget _buildMonth(
    BuildContext context,
    AsyncValue<MonthBudgetSummary> summaryAsync, {
    required YearMonth month,
    required String currencyCode,
    required String currencySymbol,
    required String locale,
    required DateTime now,
  }) {
    final notifier = ref.read(budgetViewModelProvider.notifier);
    final isHistoricalMonth = month < YearMonth.fromDate(now);
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString())),
      data: (summary) {
        final model = const BudgetUiMapper().mapScreen(
          summary,
          currencySymbol: currencySymbol,
          locale: locale,
          today: now,
        );
        final overview = model.overview;

        if (!overview.hasAnyAccount) {
          return _NoAccountsState(currencyCode: overview.currencyCode);
        }

        final reviewEntry = BudgetReviewEntryUiModel.from(model);

        void openReview() => showBudgetReview(
              context,
              month: month,
              currencyCode: currencyCode,
            );

        return ListView(
          key: PageStorageKey(month),
          padding: context.pagePadding.add(
            EdgeInsets.symmetric(vertical: context.spacing.md),
          ),
          children: [
            BudgetOverviewCard(overview: overview),
            // A closed month has nothing left to act on, so its one review
            // entry sits directly under the hero instead of at the bottom.
            if (overview.mode == BudgetMode.review) ...[
              SizedBox(height: context.spacing.sm),
              _ReviewEntry(
                key: const ValueKey('budget-review-bar'),
                entry: reviewEntry,
                onTap: openReview,
                compact: true,
              ),
            ],
            if (!overview.hasAnyBudget) ...[
              SizedBox(height: context.spacing.md),
              const _FirstBudgetCard(),
            ],
            SizedBox(height: context.spacing.lg),
            BudgetCategorySection(
              budgetedRows: model.budgetedRows,
              unbudgetedActiveRows: model.unbudgetedActiveRows,
              // Untouched categories live in the "+" drawer now; handing the
              // section none keeps a single entry point for them.
              remainingActiveRows: const [],
              showRemaining: false,
              onToggleRemaining: notifier.toggleRemainingCategories,
              onRowTap: (row) => showBudgetCategoryDetail(
                context,
                month: month,
                categoryId: row.categoryId,
              ),
              onSetBudgetTap: (row) => showBudgetEditSheet(
                context,
                row: row,
                currencyCode: currencyCode,
                currencySymbol: currencySymbol,
                month: month,
                isHistoricalMonth: isHistoricalMonth,
              ),
            ),
            if (overview.mode == BudgetMode.track) ...[
              SizedBox(height: context.spacing.lg),
              _ReviewEntry(
                key: const ValueKey('budget-review-entry'),
                entry: reviewEntry,
                onTap: openReview,
              ),
            ],
            if (overview.mode == BudgetMode.plan) ...[
              SizedBox(height: context.spacing.lg),
              _PlanHint(
                key: const ValueKey('budget-plan-hint'),
                model: BudgetPlanHintUiModel.from(model),
              ),
            ],
            const SizedBox(height: _bottomReach),
          ],
        );
      },
    );
  }

  Future<void> _pickCategoryToEdit(
    BuildContext context, {
    required List<BudgetCategoryRowUiModel> rows,
    required String currencyCode,
    required String currencySymbol,
    required YearMonth month,
    required bool isHistoricalMonth,
  }) async {
    final l10n = AppLocalizations.of(context)!;
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
                itemCount: rows.length,
                separatorBuilder: (_, __) => const FeatherDivider(),
                itemBuilder: (ctx, i) {
                  final row = rows[i];
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
                    // Every row here is budget-free by construction.
                    trailing: Text(
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

/// The tracked month's way into L2: the review's name, one line of it, and the
/// month note's opening words.
///
/// [compact] draws the closed month's summary bar — the same words on a
/// subdued surface with tighter padding, since there it sits directly under the
/// hero rather than at the end of the page.
class _ReviewEntry extends StatelessWidget {
  final BudgetReviewEntryUiModel entry;
  final VoidCallback onTap;
  final bool compact;

  const _ReviewEntry({
    super.key,
    required this.entry,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final content = Row(
      children: [
        Icon(
          LucideIcons.barChart2,
          size: compact ? 18 : context.metrics.iconSize,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.budgetReviewTitle,
                style: AppTypography.selectedLabel(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacing.xs),
              Text(
                _reviewEntryLine(l10n, entry),
                style: AppTypography.meta(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (entry.notePreview != null) ...[
                SizedBox(height: spacing.xs),
                Text(
                  l10n.budgetReviewNotePreview(entry.notePreview!),
                  style: AppTypography.meta(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return AppCard.day(
        onTap: onTap,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        child: content,
      );
    }
    return AppCard(onTap: onTap, child: content);
  }
}

/// The plan month's replacement for the review entry: what is already spoken
/// for, in one line.
class _PlanHint extends StatelessWidget {
  final BudgetPlanHintUiModel model;

  const _PlanHint({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final clauses = model.parts.map((part) => switch (part) {
          BudgetPlanHintPart.carryForward => l10n.budgetPlanHintCarryForward,
          BudgetPlanHintPart.fixedBills =>
            l10n.budgetPlanHintFixedBills(model.fixedBillsDisplay),
          BudgetPlanHintPart.noBillsYet => l10n.budgetPlanHintNoBills,
        });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(clauses.join(' · '), style: AppTypography.meta(context)),
        if (model.showMaterializedHint) ...[
          SizedBox(height: context.spacing.xs),
          Text(
            l10n.budgetMaterializedOnlyHint,
            style: AppTypography.meta(context),
          ),
        ],
      ],
    );
  }
}

/// A month with no limit at all: the page still has to say where the first one
/// comes from.
class _FirstBudgetCard extends StatelessWidget {
  const _FirstBudgetCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
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
    );
  }
}

class _NoAccountsState extends StatelessWidget {
  final String currencyCode;

  const _NoAccountsState({required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.wallet,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              l10n.budgetEmptyNoAccountsTitle,
              style: AppTypography.sectionTitle(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.xs),
            Text(
              l10n.budgetEmptyNoAccountsBody(currencyCode),
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
}

/// Resolves the entry's meaning to words. The kinds are named by the model and
/// the amounts arrive preformatted; this is the one place the two meet.
String _reviewEntryLine(
  AppLocalizations l10n,
  BudgetReviewEntryUiModel entry,
) {
  return switch (entry.kind) {
    BudgetReviewEntryKind.overrun => l10n.budgetReviewEntryOverrun(
        entry.categoryName!,
        entry.amountDisplay!,
      ),
    BudgetReviewEntryKind.surplus => l10n.budgetReviewEntrySurplus(
        entry.categoryName!,
        entry.amountDisplay!,
      ),
    BudgetReviewEntryKind.quiet => l10n.budgetReviewEntryQuiet,
  };
}
