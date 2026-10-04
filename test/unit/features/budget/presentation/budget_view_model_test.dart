import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/view_model/budget_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

import '../../../../support/fakes/fake_app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = FakeAppDatabase();
    await db.into(db.categoriesView).insert(
          CategoriesViewCompanion.insert(
            id: 'dining',
            name: 'Dining',
            iconKey: 'utensils',
            colorInt: 0xFFE65100,
            type: CategoryType.expense,
            lastUpdatedEventId: 1,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('BudgetViewModel manages month, preview/remaining toggles, and commands',
      () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        budgetClockProvider.overrideWithValue(FixedClock(DateTime(2026, 5, 10))),
        ledgerCurrencyProvider.overrideWithValue('CNY'),
      ],
    );
    addTearDown(container.dispose);

    final initial = container.read(budgetViewModelProvider);
    expect(initial.selectedMonth, const YearMonth(2026, 5));
    expect(initial.isReviewPreview, isFalse);
    expect(initial.showRemainingCategories, isFalse);

    final notifier = container.read(budgetViewModelProvider.notifier);
    notifier.toggleReviewPreview();
    notifier.toggleRemainingCategories();
    expect(container.read(budgetViewModelProvider).isReviewPreview, isTrue);
    expect(container.read(budgetViewModelProvider).showRemainingCategories,
        isTrue);

    notifier.setMonth(DateTime(2026, 4, 1));
    expect(
      container.read(budgetViewModelProvider).selectedMonth,
      const YearMonth(2026, 4),
    );
    // Changing month resets review preview toggle cleanly.
    expect(container.read(budgetViewModelProvider).isReviewPreview, isFalse);

    final res = await notifier.setCategoryBudget(
      currencyCode: 'CNY',
      categoryId: 'dining',
      month: const YearMonth(2026, 4),
      amountMinor: 150000,
      scope: BudgetEditScope.thisAndFollowing,
    );
    expect(res.isSuccess, isTrue);

    final sub = container.listen(
      budgetMonthSummaryProvider(const YearMonth(2026, 4)),
      (_, __) {},
    );
    addTearDown(sub.close);

    final summary = await container
        .read(budgetMonthSummaryProvider(const YearMonth(2026, 4)).future);
    expect(summary.totalBudgetMinor, 150000);
  });
}
