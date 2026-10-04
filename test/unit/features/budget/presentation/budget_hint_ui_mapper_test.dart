import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/mappers/budget_hint_ui_mapper.dart';
import 'package:feather_ledger/features/budget/presentation/models/budget_hint_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/transaction_form_view_state.dart';

void main() {
  const mapper = BudgetHintUiMapper();
  const baseHint = CategoryBudgetHint(
    currencyCode: 'CNY',
    month: YearMonth(2026, 5),
    categoryId: 'dining',
    isCategoryArchived: false,
    effectiveBudgetMinor: 100000,
    actualMinor: 60000,
    pendingMinor: 20000,
  );

  TransactionTileUiModel makeOriginal({
    required String categoryId,
    required DateTime date,
    required int amountMinor,
    bool includeInTotals = true,
  }) {
    return TransactionTileUiModel(
      id: 'tx-1',
      note: 'Meal',
      date: date,
      amount: amountMinor,
      displayAmount: '¥200.00',
      displaySign: '-',
      type: TransactionKind.expense,
      account: AccountEntity(
        id: 'acc-1',
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'CNY',
        balanceMinor: 50000,
        archived: false,
        includeInTotals: includeInTotals,
        lastUpdatedEventId: 1,
      ),
      category: CategoryEntity(
        id: categoryId,
        name: 'Dining',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: CategoryType.expense,
      ),
    );
  }

  group('BudgetHintUiMapper', () {
    test('handles excluded account and historical planned states', () {
      final excluded = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 10000,
        selectedAccountIncludeInTotals: false,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: null,
        currencySymbol: '¥',
      );
      expect(excluded.status, BudgetHintStatus.excludedAccount);

      final pastPlanned = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.planned,
        inputAmountMinor: 10000,
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 4),
        nowYm: const YearMonth(2026, 5),
        original: null,
        currencySymbol: '¥',
      );
      expect(pastPlanned.status, BudgetHintStatus.pastPlanned);
    });

    test('computes withinBudget, atRisk, overBudget, and unset states', () {
      final within = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 10000,
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: null,
        currencySymbol: '¥',
      );
      expect(within.status, BudgetHintStatus.withinBudget);
      expect(within.primaryAmountDisplay, '¥200.00');
      expect(within.secondaryAmountDisplay, '¥100.00');

      final atRisk = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 30000, // 600 + 300 <= 1000, +200 pending > 1000
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: null,
        currencySymbol: '¥',
      );
      expect(atRisk.status, BudgetHintStatus.atRisk);
      expect(atRisk.primaryAmountDisplay, '¥100.00');

      final over = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 50000,
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: null,
        currencySymbol: '¥',
      );
      expect(over.status, BudgetHintStatus.overBudget);
      expect(over.primaryAmountDisplay, '¥100.00');

      final unset = mapper.map(
        hint: const CategoryBudgetHint(
          currencyCode: 'CNY',
          month: YearMonth(2026, 5),
          categoryId: 'dining',
          isCategoryArchived: false,
          effectiveBudgetMinor: null,
          actualMinor: 45000,
          pendingMinor: 0,
        ),
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 10000,
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: null,
        currencySymbol: '¥',
      );
      expect(unset.status, BudgetHintStatus.unset);
      expect(unset.primaryAmountDisplay, '¥450.00');
    });

    test(
        'only subtracts original amount when editing same (month, category) '
        'with includeInTotals', () {
      final sameBucket = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 30000,
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: makeOriginal(
          categoryId: 'dining',
          date: DateTime(2026, 5, 2),
          amountMinor: 20000,
        ),
        currencySymbol: '¥',
      );
      // baseActual = 600 - 200 = 400; beforeProj = 1000 - 400 - 200 = 400; after = 100
      expect(sameBucket.status, BudgetHintStatus.withinBudget);
      expect(sameBucket.primaryAmountDisplay, '¥400.00');
      expect(sameBucket.secondaryAmountDisplay, '¥100.00');

      final movedMonth = mapper.map(
        hint: baseHint,
        categoryId: 'dining',
        mode: TransactionFormMode.defaultMode,
        inputAmountMinor: 30000,
        selectedAccountIncludeInTotals: true,
        targetYm: const YearMonth(2026, 5),
        nowYm: const YearMonth(2026, 5),
        original: makeOriginal(
          categoryId: 'dining',
          date: DateTime(2026, 4, 2),
          amountMinor: 20000,
        ),
        currencySymbol: '¥',
      );
      // Original was in April, so May baseline stays 600 + 200 pending -> 300 puts +pending 100 over
      expect(movedMonth.status, BudgetHintStatus.atRisk);
      expect(movedMonth.primaryAmountDisplay, '¥100.00');
    });
  });
}
