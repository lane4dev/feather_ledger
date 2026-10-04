import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_state.dart';

import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_hint_ui_mapper.dart';
import '../models/budget_hint_ui_model.dart';
import '../view_model/transaction_budget_hint_provider.dart';

class TransactionBudgetHintBanner extends ConsumerWidget {
  final String currencyCode;
  final String currencySymbol;
  final YearMonth month;
  final String categoryId;
  final TransactionFormMode mode;
  final int inputAmountMinor;
  final bool selectedAccountIncludeInTotals;
  final TransactionTileUiModel? original;

  const TransactionBudgetHintBanner({
    super.key,
    required this.currencyCode,
    required this.currencySymbol,
    required this.month,
    required this.categoryId,
    required this.mode,
    required this.inputAmountMinor,
    required this.selectedAccountIncludeInTotals,
    required this.original,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hintAsync = ref.watch(
      transactionBudgetHintProvider(
        currencyCode: currencyCode,
        month: month,
        categoryId: categoryId,
      ),
    );
    final nowYm = YearMonth.fromDate(ref.read(budgetClockProvider).now());
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;

    return hintAsync.maybeWhen(
      data: (hint) {
        final ui = const BudgetHintUiMapper().map(
          hint: hint,
          categoryId: categoryId,
          mode: mode,
          inputAmountMinor: inputAmountMinor,
          selectedAccountIncludeInTotals: selectedAccountIncludeInTotals,
          targetYm: month,
          nowYm: nowYm,
          original: original,
          currencySymbol: currencySymbol,
        );

        final (IconData icon, Color tint, String text) = switch (ui.status) {
          BudgetHintStatus.excludedAccount => (
              LucideIcons.eyeOff,
              scheme.onSurfaceVariant,
              l10n.budgetHintExcludedAccount,
            ),
          BudgetHintStatus.pastPlanned => (
              LucideIcons.history,
              scheme.onSurfaceVariant,
              l10n.budgetHintPastPlanned,
            ),
          BudgetHintStatus.unset => (
              LucideIcons.info,
              scheme.onSurfaceVariant,
              l10n.budgetHintUnset(ui.primaryAmountDisplay),
            ),
          BudgetHintStatus.withinBudget => (
              LucideIcons.circleCheck,
              context.colors.income,
              l10n.budgetHintRemaining(
                ui.primaryAmountDisplay,
                ui.secondaryAmountDisplay ?? ui.primaryAmountDisplay,
              ),
            ),
          BudgetHintStatus.atRisk => (
              LucideIcons.clock,
              context.colors.frequency,
              l10n.budgetHintAtRisk(ui.primaryAmountDisplay),
            ),
          BudgetHintStatus.overBudget => (
              LucideIcons.triangleAlert,
              context.colors.expense,
              l10n.budgetHintOver(ui.primaryAmountDisplay),
            ),
        };

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: context.metrics.controlBorderRadius,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: tint),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.compactLabel(context).copyWith(
                    color: ui.status == BudgetHintStatus.overBudget
                        ? context.colors.expense
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
