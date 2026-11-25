import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_review_ui_mapper.dart';
import '../models/budget_review_ui_models.dart';
import '../view_model/budget_view_model.dart';
import '../widgets/budget_attribution_card.dart';
import '../widgets/budget_month_note_card.dart';
import '../widgets/budget_trend_chart.dart';
import '../widgets/scrolled_tint_scaffold.dart';
import 'budget_category_detail_screen.dart';

/// Opens the L2 monthly review page on the root navigator.
///
/// Mirrors [showBudgetCategoryDetail]: the page covers the shell, and its back
/// arrow returns to the budget home with the same month and scroll position.
Future<void> showBudgetReview(
  BuildContext context, {
  required YearMonth month,
  required String currencyCode,
}) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/budget/review'),
      transitionDuration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 320),
      reverseTransitionDuration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) =>
          BudgetReviewScreen(month: month, currencyCode: currencyCode),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// L2 monthly review: whole-month committed/flexible actuals, the committed
/// baseline, over/under attribution, the six-month trend and the month note.
///
/// Scope is the whole month (unbudgeted categories included), so the figures
/// here intentionally differ from the budgeted-only numbers on the home card.
/// Tapping an attribution row opens the same month's L3 category detail.
class BudgetReviewScreen extends ConsumerWidget {
  final YearMonth month;
  final String currencyCode;

  const BudgetReviewScreen({
    super.key,
    required this.month,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(budgetMonthSummaryProvider(month));
    final scheme = Theme.of(context).colorScheme;
    final monthLabel =
        DateFormat.yMMMM(Localizations.localeOf(context).toString())
            .format(month.toDateTime());

    return ScrolledTintScaffold(
      appBarBuilder: (context, scrolledUnder) => AppBar(
        backgroundColor: scrolledUnder ? scheme.surfaceContainer : null,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                l10n.budgetReviewTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: context.spacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.sm,
                vertical: context.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                monthLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: context.pagePadding,
            child: Text(l10n.errorUnknownEvent, textAlign: TextAlign.center),
          ),
        ),
        data: (summary) {
          final model = const BudgetReviewUiMapper().map(
            summary,
            currencySymbol: ref.watch(displayCurrencySymbolProvider),
            locale: Localizations.localeOf(context).toString(),
            today: ref.watch(budgetClockProvider).now(),
          );
          return _BudgetReviewBody(model: model, currencyCode: currencyCode);
        },
      ),
    );
  }
}

class _BudgetReviewBody extends StatelessWidget {
  final BudgetReviewUiModel model;
  final String currencyCode;

  const _BudgetReviewBody({required this.model, required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final showTrend = BudgetTrendChart.shouldShow(model.monthTrend6Months);

    return ListView(
      padding:
          context.pagePadding.copyWith(top: spacing.md, bottom: spacing.xl),
      children: [
        _ActualsCard(model: model),
        if (model.hasAttribution) ...[
          SizedBox(height: spacing.md),
          BudgetAttributionCard(
            overBudgetTop3: model.overBudgetTop3,
            underBudgetTop3: model.underBudgetTop3,
            onCategoryTap: (categoryId) => showBudgetCategoryDetail(
              context,
              month: model.month,
              categoryId: categoryId,
            ),
          ),
        ],
        if (showTrend) ...[
          SizedBox(height: spacing.md),
          BudgetTrendChart(points: model.monthTrend6Months),
        ],
        SizedBox(height: spacing.md),
        BudgetMonthNoteCard(
          month: model.month,
          monthLabel: model.monthLabel,
          currencyCode: currencyCode,
          note: model.monthReviewNote,
          noteUpdatedDisplay: model.monthReviewNoteUpdatedDisplay,
        ),
      ],
    );
  }
}

class _ActualsCard extends StatelessWidget {
  final BudgetReviewUiModel model;

  const _ActualsCard({required this.model});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.budgetReviewCompositionSubtitle,
            style: AppTypography.meta(context),
          ),
          SizedBox(height: spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Metric(
                  label: l10n.budgetReviewCommittedActual,
                  value: model.committedActualDisplay,
                ),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: _Metric(
                  label: l10n.budgetReviewDiscretionaryActual,
                  value: model.discretionaryActualDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          _CompositionBar(
            committedMinor: model.committedActualMinor,
            discretionaryMinor: model.discretionaryActualMinor,
          ),
          if (model.showBaselineRow) ...[
            SizedBox(height: spacing.md),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.budgetReviewBaselineRow,
                    style: AppTypography.meta(context),
                  ),
                ),
                Text(
                  model.committedBaselineDisplay,
                  style: AppTypography.amount(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The 6dp committed/flexible proportion strip under the two figures.
class _CompositionBar extends StatelessWidget {
  final int committedMinor;
  final int discretionaryMinor;

  const _CompositionBar({
    required this.committedMinor,
    required this.discretionaryMinor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = committedMinor + discretionaryMinor;
    return Container(
      key: const ValueKey('budget-review-composition-bar'),
      height: 6,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3),
      ),
      child: total <= 0
          ? null
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (committedMinor > 0)
                  Expanded(
                    flex: committedMinor,
                    child: ColoredBox(color: scheme.primary),
                  ),
                if (discretionaryMinor > 0)
                  Expanded(
                    flex: discretionaryMinor,
                    child: ColoredBox(color: scheme.tertiary),
                  ),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.meta(context)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTypography.statistic(context),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
