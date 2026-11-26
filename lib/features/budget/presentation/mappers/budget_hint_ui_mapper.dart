import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_state.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../../domain/entities/budget_entities.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../models/budget_hint_ui_model.dart';

class BudgetHintUiMapper {
  const BudgetHintUiMapper();

  BudgetHintUiModel map({
    required CategoryBudgetHint hint,
    required String categoryId,
    required TransactionFormMode mode,
    required int inputAmountMinor,
    required bool selectedAccountIncludeInTotals,
    required YearMonth targetYm,
    required YearMonth nowYm,
    required TransactionTileUiModel? original,
    required String currencySymbol,
  }) {
    if (!selectedAccountIncludeInTotals) {
      return const BudgetHintUiModel(
        status: BudgetHintStatus.excludedAccount,
        primaryAmountDisplay: '',
      );
    }

    final isSeriesMode = mode != TransactionFormMode.defaultMode;
    if (isSeriesMode && targetYm < nowYm) {
      return const BudgetHintUiModel(
        status: BudgetHintStatus.pastPlanned,
        primaryAmountDisplay: '',
      );
    }

    final originalContributed = original != null &&
        original.type == TransactionKind.expense &&
        original.category?.id == categoryId &&
        YearMonth.fromDate(original.date) == targetYm &&
        original.account.includeInTotals;

    final baseActual =
        (hint.actualMinor - (originalContributed ? original.amount : 0))
            .clamp(0, 1 << 62);
    final basePending = targetYm < nowYm ? 0 : hint.pendingMinor;

    final budgetMinor = hint.effectiveBudgetMinor;
    if (budgetMinor == null) {
      return BudgetHintUiModel(
        status: BudgetHintStatus.unset,
        primaryAmountDisplay:
            formatMinorWithSymbol(baseActual, currencySymbol),
      );
    }

    final deltaActual = isSeriesMode ? 0 : inputAmountMinor;
    final deltaPending = isSeriesMode ? inputAmountMinor : 0;

    final afterActual = baseActual + deltaActual;
    final afterPending = basePending + deltaPending;

    final beforeProjectedRemaining = budgetMinor - baseActual - basePending;
    final afterProjectedRemaining = budgetMinor - afterActual - afterPending;
    final afterActualRemaining = budgetMinor - afterActual;

    if (afterActualRemaining < 0) {
      return BudgetHintUiModel(
        status: BudgetHintStatus.overBudget,
        primaryAmountDisplay: formatMinorWithSymbol(
          afterActualRemaining.abs(),
          currencySymbol,
        ),
      );
    }

    if (afterProjectedRemaining < 0) {
      return BudgetHintUiModel(
        status: BudgetHintStatus.atRisk,
        primaryAmountDisplay: formatMinorWithSymbol(
          afterProjectedRemaining.abs(),
          currencySymbol,
        ),
      );
    }

    return BudgetHintUiModel(
      status: BudgetHintStatus.withinBudget,
      primaryAmountDisplay: formatMinorWithSymbol(
        beforeProjectedRemaining,
        currencySymbol,
      ),
      secondaryAmountDisplay: formatMinorWithSymbol(
        afterProjectedRemaining,
        currencySymbol,
      ),
    );
  }
}
