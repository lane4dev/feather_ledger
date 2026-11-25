import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../../domain/commands/save_review_note_command.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_review_ui_mapper.dart';
import '../models/budget_review_ui_models.dart';
import '../view_model/budget_view_model.dart';
import '../widgets/budget_attribution_card.dart';
import '../widgets/budget_trend_chart.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.budgetReviewTitle),
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
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final showTrend =
        BudgetTrendChart.shouldShow(model.monthTrend6Months);

    return ListView(
      padding: context.pagePadding.copyWith(top: spacing.md, bottom: spacing.xl),
      children: [
        Text(
          model.monthLabel,
          style: AppTypography.sectionTitle(context),
        ),
        SizedBox(height: spacing.xs),
        Text(
          l10n.budgetReviewScopeNote,
          style: AppTypography.meta(context),
        ),
        SizedBox(height: spacing.md),
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
          BudgetTrendChart(
            points: model.monthTrend6Months,
            budgetLineChartValue: model.budgetLineChartValue,
          ),
        ],
        SizedBox(height: spacing.md),
        _MonthNoteCard(
          month: model.month,
          currencyCode: currencyCode,
          note: model.monthReviewNote,
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(height: spacing.md),
          _Metric(
            label: l10n.budgetCommittedBaseline,
            value: model.committedBaselineDisplay,
          ),
          SizedBox(height: spacing.xs),
          Text(
            l10n.budgetReviewBaselineNote,
            style: AppTypography.meta(context),
          ),
          if (model.hasLeftoverPendingBills) ...[
            SizedBox(height: spacing.sm),
            Text(
              l10n.budgetLeftoverPendingHint,
              style: AppTypography.meta(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

class _MonthNoteCard extends ConsumerStatefulWidget {
  final YearMonth month;
  final String currencyCode;
  final String? note;

  const _MonthNoteCard({
    required this.month,
    required this.currencyCode,
    required this.note,
  });

  @override
  ConsumerState<_MonthNoteCard> createState() => _MonthNoteCardState();
}

class _MonthNoteCardState extends ConsumerState<_MonthNoteCard> {
  late final TextEditingController _controller;
  String? _savedNote;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savedNote = _normalize(widget.note);
    _controller = TextEditingController(text: _savedNote ?? '');
  }

  @override
  void didUpdateWidget(covariant _MonthNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.note != widget.note) {
      _savedNote = _normalize(widget.note);
      _controller.text = _savedNote ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String? _normalize(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _startEditing() {
    _controller.text = _savedNote ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _controller.text = _savedNote ?? '';
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final raw = _controller.text;
    if (raw.trim().runes.length > SaveReviewNoteCommand.maxLength) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorBudgetNoteTooLong)),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await ref
        .read(budgetViewModelProvider.notifier)
        .saveReviewNote(
          currencyCode: widget.currencyCode,
          month: widget.month,
          note: raw,
        );
    if (!mounted) return;

    setState(() {
      _saving = false;
      switch (result) {
        case Success():
          _editing = false;
          _savedNote = _normalize(raw);
          _controller.text = _savedNote ?? '';
        case Failure():
          // Keep the draft so the user can shorten and retry.
          _editing = true;
      }
    });

    final message = switch (result) {
      Success() => l10n.budgetNoteSaved,
      Failure(:final code) => code.message(l10n),
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final length = _controller.text.runes.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetMonthNoteLabel,
                  style: AppTypography.sectionTitle(context),
                ),
              ),
              if (!_editing)
                TextButton.icon(
                  onPressed: _startEditing,
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
          if (_editing) ...[
            SizedBox(height: spacing.sm),
            AppTextField(
              controller: _controller,
              minLines: 3,
              maxLines: 4,
              hintText: l10n.budgetNotePlaceholder,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: spacing.xs),
            Text(
              l10n.budgetNoteCharCount(length),
              style: AppTypography.compactLabel(context).copyWith(
                color: length > SaveReviewNoteCommand.maxLength
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
            Text(
              l10n.budgetReviewNoteEmptyDeletes,
              style: AppTypography.meta(context),
            ),
            SizedBox(height: spacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: spacing.xs,
              runSpacing: spacing.xs,
              children: [
                AppButton.text(
                  onPressed: _saving ? null : _cancelEditing,
                  child: Text(l10n.cancel),
                ),
                AppButton.outlined(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.budgetSaveNote),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: spacing.xs),
            Text(
              _savedNote ?? l10n.budgetNotePlaceholder,
              style: _savedNote == null
                  ? AppTypography.meta(context)
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
