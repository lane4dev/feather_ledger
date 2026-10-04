import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/entities/budget_entities.dart';
import 'package:feather_ledger/features/budget/domain/services/budget_service.dart';
import 'package:feather_ledger/features/budget/domain/value_objects/budget_value_objects.dart';
import 'package:feather_ledger/features/budget/presentation/models/budget_ui_models.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_drilldown_sheet.dart';
import 'package:feather_ledger/features/budget/presentation/widgets/budget_edit_sheet.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';

class _StubBudgetService implements BudgetService {
  final MonthBudgetSummary summary;
  bool hasFuture = false;
  String? savedNote;
  BudgetEditScope? lastScope;
  int? lastAmountMinor;

  _StubBudgetService(this.summary);

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) =>
      Stream.value(summary);

  @override
  Stream<CategoryBudgetHint> watchTransactionBudgetHint({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) =>
      const Stream.empty();

  @override
  Future<bool> hasFutureRulesAfter({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
  }) async =>
      hasFuture;

  @override
  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) async {
    lastAmountMinor = amountMinor;
    lastScope = scope;
    return unitResult;
  }

  @override
  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) async {
    lastScope = scope;
    return unitResult;
  }

  @override
  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async {
    if (note.trim().runes.length > 500) {
      return const Result.failure(
          LedgerErrorCode.budgetNoteTooLong, 'too long');
    }
    savedNote = note.trim();
    return unitResult;
  }
}

class _StubLedgerRepository implements LedgerRepository {
  @override
  Future<TransactionEntity?> getTransaction(String id) async {
    return TransactionEntity(
      id: id,
      note: 'Lunch',
      amount: -4500,
      type: TransactionKind.expense,
      date: DateTime(2026, 5, 10),
      eventId: 1,
      account: const AccountEntity(
        id: 'acc-1',
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 10000,
        archived: false,
        lastUpdatedEventId: 1,
      ),
      category: const CategoryEntity(
        id: 'dining',
        name: 'Dining',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: CategoryType.expense,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  MonthBudgetSummary buildSummary() {
    final dining = CategoryBudgetSummary(
      categoryId: 'dining',
      categoryName: 'Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      isArchived: false,
      archiveYm: null,
      budgetMinor: 100000,
      hasFutureRulesAfter: false,
      committedActualMinor: 0,
      discretionaryActualMinor: 45000,
      actualMinor: 45000,
      pendingMinor: 0,
      projectedRemainingMinor: 55000,
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 0,
      isAnomaly: false,
      anomalyDeltaRatio: null,
      riskLevel: BudgetRiskLevel.inBudget,
      sixMonthTrend: const [
        BudgetTrendPoint(
          month: YearMonth(2026, 5),
          budgetMinor: 100000,
          actualMinor: 45000,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
      ],
      topTransactions: [
        BudgetContributionTx(
          transactionId: 'tx-1',
          sourceScheduledBillId: null,
          scheduledBillId: null,
          description: 'Lunch',
          occurredAt: DateTime(2026, 5, 10),
          amountMinor: 45000,
          isPending: false,
        ),
      ],
      reviewNote: 'Old note',
    );
    return MonthBudgetSummary(
      currencyCode: 'USD',
      month: const YearMonth(2026, 5),
      mode: BudgetMode.track,
      hasAnyActiveAccount: true,
      totalBudgetMinor: 100000,
      budgetedActualMinor: 45000,
      budgetedPendingMinor: 0,
      projectedRemainingMinor: 55000,
      budgetedRemainingActualMinor: 55000,
      allExpenseActualMinor: 45000,
      allExpensePendingMinor: 0,
      unbudgetedActualMinor: 0,
      unbudgetedPendingMinor: 0,
      inBudgetCount: 1,
      budgetedCategoryCount: 1,
      complianceRate: 1.0,
      hasAnyBudget: true,
      hasUnbudgetedActivity: false,
      hasLeftoverPendingInReview: false,
      hasHighFrequencyPending: false,
      isFarFutureMaterializedOnly: false,
      budgetedCategories: [dining],
      unbudgetedActiveCategories: const [],
      remainingActiveCategories: const [],
      overBudgetTop3: const [],
      underBudgetTop3: const [],
      unbudgetedAlertsTop3: const [],
      monthTrend6Months: const [
        BudgetTrendPoint(
          month: YearMonth(2026, 5),
          budgetMinor: 100000,
          actualMinor: 45000,
          pendingMinor: 0,
          hasReviewNote: false,
        ),
      ],
      monthReviewNote: null,
    );
  }

  testWidgets(
      'BudgetDrilldownSheet navigates to /ledger/edit and validates Review Note length',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = _StubBudgetService(buildSummary());
    String? pushedEditId;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showBudgetDrilldownSheet(
                  ctx,
                  month: const YearMonth(2026, 5),
                  categoryId: 'dining',
                ),
                child: const Text('Open drilldown'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/ledger/edit',
          builder: (_, state) {
            final tile = state.extra as TransactionTileUiModel?;
            pushedEditId = tile?.id;
            return const Scaffold(body: Text('Edit Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetClockProvider
              .overrideWithValue(FixedClock(DateTime(2026, 5, 15))),
          budgetServiceProvider.overrideWithValue(service),
          ledgerRepositoryProvider.overrideWithValue(_StubLedgerRepository()),
          ledgerCurrencyProvider.overrideWithValue('USD'),
          displayCurrencySymbolProvider.overrideWithValue('\$'),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open drilldown'));
    await tester.pumpAndSettle();

    // 88% height check
    final sized = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.text('Dining'),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(sized.height, closeTo(2400 * 0.88, 1.0));

    // Too long note triggers error SnackBar
    final noteField = find.byType(TextField);
    await tester.enterText(noteField, 'x' * 501);
    await tester.pump();
    await tester.ensureVisible(find.text('Save note'));
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(find.textContaining('500'), findsWidgets);
    expect(service.savedNote, isNull);

    // Valid note saves
    await tester.enterText(noteField, 'Good month');
    await tester.pump();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(service.savedNote, 'Good month');

    // Tapping TOP transaction pushes /ledger/edit
    await tester.ensureVisible(find.text('Lunch'));
    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(pushedEditId, 'tx-1');
    expect(find.text('Edit Screen'), findsOneWidget);
  });

  testWidgets(
      'BudgetEditSheet enforces >0 save guard, fills baseline chips, and '
      'forces scope picker when future breakpoints exist', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = _StubBudgetService(buildSummary())..hasFuture = true;
    const row = BudgetCategoryRowUiModel(
      categoryId: 'dining',
      name: 'Dining',
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      archived: false,
      isBudgetEditable: true,
      budgetMinor: null, // Unset in May, BUT future rule exists!
      lastMonthActualMinor: 80000,
      threeMonthAvgMinor: 75000,
      committedBaselineMinor: 15000,
      budgetDisplay: null,
      actualDisplay: '\$200.00',
      pendingDisplay: null,
      varianceDisplay: null,
      isOverBudget: false,
      committedActualDisplay: '\$0.00',
      discretionaryActualDisplay: '\$200.00',
      committedBaselineDisplay: '\$150.00',
      lastMonthActualDisplay: '\$800.00',
      threeMonthAvgDisplay: '\$750.00',
      actualProgress: 0,
      pendingProgress: 0,
      riskLevel: BudgetRiskLevel.inBudget,
      isAnomaly: false,
      anomalyPercent: null,
      trend6Months: [],
      topContributions: [],
      reviewNote: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: BudgetEditSheet(
              row: row,
              currencyCode: 'USD',
              currencySymbol: '\$',
              month: const YearMonth(2026, 5),
              isHistoricalMonth: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Future breakpoints exist -> scope picker MUST appear with warning
    expect(find.text('This & following months'), findsOneWidget);
    expect(find.textContaining('will be replaced'), findsOneWidget);

    // Entering 0 shows hint & keeps Save disabled
    await tester.enterText(
      find.descendant(
        of: find.byType(LedgerAmountInput),
        matching: find.byType(TextFormField),
      ),
      '0',
    );
    await tester.pump();
    expect(find.textContaining('greater than 0'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(service.lastAmountMinor, isNull);

    // Tapping baseline chip fills amount and enables Save
    await tester.tap(find.textContaining('Last mo'));
    await tester.pump();
    await tester.tap(find.text('This month only'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(service.lastAmountMinor, 80000);
    expect(service.lastScope, BudgetEditScope.thisMonthOnly);
  });
}
