import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
import 'package:feather_ledger/features/budget/presentation/screens/budget_category_detail_screen.dart';
import 'package:feather_ledger/features/budget/presentation/screens/budget_review_screen.dart';
import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

class _StubBudgetService implements BudgetService {
  _StubBudgetService(this.summary, {this.saveResult});

  final MonthBudgetSummary summary;
  final Result<void>? saveResult;

  String? savedNote;
  int saveCalls = 0;

  @override
  Stream<MonthBudgetSummary> watchMonthBudget({
    required String currencyCode,
    required YearMonth month,
  }) async* {
    yield summary;
  }

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
      false;

  @override
  Future<Result<void>> setCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required int amountMinor,
    required BudgetEditScope scope,
  }) async =>
      unitResult;

  @override
  Future<Result<void>> clearCategoryBudget({
    required String currencyCode,
    required String categoryId,
    required YearMonth month,
    required BudgetEditScope scope,
  }) async =>
      unitResult;

  @override
  Future<Result<void>> saveReviewNote({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async {
    saveCalls++;
    if (saveResult != null) return saveResult!;
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

  const may = YearMonth(2026, 5);

  CategoryBudgetSummary category({
    required String id,
    required String name,
    int? budgetMinor,
    required int committedActualMinor,
    required int discretionaryActualMinor,
  }) {
    return CategoryBudgetSummary(
      categoryId: id,
      categoryName: name,
      iconKey: 'utensils',
      colorInt: 0xFFE65100,
      isArchived: false,
      archiveYm: null,
      budgetMinor: budgetMinor,
      hasFutureRulesAfter: false,
      committedActualMinor: committedActualMinor,
      discretionaryActualMinor: discretionaryActualMinor,
      actualMinor: committedActualMinor + discretionaryActualMinor,
      pendingMinor: 0,
      projectedRemainingMinor: 0,
      lastMonthActualMinor: 0,
      threeMonthAvgMinor: 0,
      committedBaselineMinor: committedActualMinor,
      isAnomaly: false,
      anomalyDeltaRatio: null,
      riskLevel: BudgetRiskLevel.inBudget,
      sixMonthTrend: const [],
      topTransactions: const [],
      allTransactions: const [],
      reviewNote: null,
    );
  }

  MonthBudgetSummary buildSummary({
    String? note,
    List<BudgetTrendPoint>? trend,
    bool hasLeftoverPendingInReview = false,
  }) {
    final dining = category(
      id: 'dining',
      name: 'Dining',
      budgetMinor: 20000,
      committedActualMinor: 40000,
      discretionaryActualMinor: 60000,
    );
    final medical = category(
      id: 'medical',
      name: 'Medical',
      committedActualMinor: 0,
      discretionaryActualMinor: 200000,
    );
    return MonthBudgetSummary(
      currencyCode: 'USD',
      month: may,
      mode: BudgetMode.review,
      hasAnyActiveAccount: true,
      totalBudgetMinor: 20000,
      budgetedActualMinor: 100000,
      budgetedPendingMinor: 0,
      projectedRemainingMinor: 0,
      budgetedRemainingActualMinor: 0,
      allExpenseActualMinor: 300000,
      allExpensePendingMinor: 0,
      unbudgetedActualMinor: 200000,
      unbudgetedPendingMinor: 0,
      inBudgetCount: 1,
      budgetedCategoryCount: 1,
      complianceRate: 0,
      hasAnyBudget: true,
      hasUnbudgetedActivity: true,
      hasLeftoverPendingInReview: hasLeftoverPendingInReview,
      hasHighFrequencyPending: false,
      isFarFutureMaterializedOnly: false,
      budgetedCategories: [dining],
      unbudgetedActiveCategories: [medical],
      remainingActiveCategories: const [],
      overBudgetTop3: const [
        BudgetAttributionItem(
          categoryId: 'dining',
          categoryName: 'Dining',
          iconKey: 'utensils',
          colorInt: 0xFFE65100,
          budgetMinor: 20000,
          actualMinor: 32000,
          varianceMinor: -12000,
          shareOfTotalActual: 0.5,
        ),
      ],
      underBudgetTop3: const [
        BudgetAttributionItem(
          categoryId: 'transport',
          categoryName: 'Transport',
          iconKey: 'bus',
          colorInt: 0xFF1565C0,
          budgetMinor: 30000,
          actualMinor: 10000,
          varianceMinor: 20000,
          shareOfTotalActual: 0.2,
        ),
      ],
      unbudgetedAlertsTop3: const [
        UnbudgetedSpendAlert(
          categoryId: 'medical',
          categoryName: 'Medical',
          iconKey: 'heart-pulse',
          colorInt: 0xFF2E7D32,
          actualMinor: 200000,
          pendingMinor: 0,
          shareOfTotalActual: 0.66,
        ),
      ],
      monthTrend6Months: trend ??
          const [
            BudgetTrendPoint(
              month: YearMonth(2026, 4),
              budgetMinor: 20000,
              actualMinor: 12000,
              pendingMinor: 0,
              hasReviewNote: false,
            ),
            BudgetTrendPoint(
              month: may,
              budgetMinor: 20000,
              actualMinor: 24000,
              pendingMinor: 0,
              hasReviewNote: true,
            ),
          ],
      monthReviewNote: note,
    );
  }

  Future<_StubBudgetService> pumpReview(
    WidgetTester tester, {
    MonthBudgetSummary? summary,
    Result<void>? saveResult,
    Size size = const Size(1200, 2400),
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _StubBudgetService(
      summary ?? buildSummary(),
      saveResult: saveResult,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        budgetClockProvider
            .overrideWithValue(FixedClock(DateTime(2026, 5, 15))),
        budgetServiceProvider.overrideWithValue(service),
        ledgerRepositoryProvider.overrideWithValue(_StubLedgerRepository()),
        ledgerCurrencyProvider.overrideWithValue('USD'),
        displayCurrencySymbolProvider.overrideWithValue('\$'),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.lightTheme
            : AppTheme.darkTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: const BudgetReviewScreen(month: may, currencyCode: 'USD'),
      ),
    ));
    await tester.pumpAndSettle();
    return service;
  }

  testWidgets('shows whole-month actuals, the committed baseline and the '
      'leftover-bill explanation', (tester) async {
    await pumpReview(
      tester,
      summary: buildSummary(hasLeftoverPendingInReview: true),
    );

    expect(find.text('Monthly Review & Trends'), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);
    expect(
      find.text('Whole month, including unbudgeted categories.'),
      findsOneWidget,
    );
    expect(find.text('Committed spent'), findsOneWidget);
    expect(find.text('\$400.00'), findsNWidgets(2));
    expect(find.text('Discretionary spent'), findsOneWidget);
    expect(find.text('\$2600.00'), findsOneWidget);
    expect(find.text('Committed baseline'), findsOneWidget);
    expect(
      find.text(
        'Committed spent + effective pending bills. Reference only; the three '
        'figures are not additive.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Past month has unposted scheduled bills excluded from review totals.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('omits the leftover-bill explanation when nothing is pending',
      (tester) async {
    await pumpReview(tester);

    expect(
      find.text(
        'Past month has unposted scheduled bills excluded from review totals.',
      ),
      findsNothing,
    );
  });

  testWidgets('shows over and under budget side by side in domain order and '
      'opens the same-month L3 on tap', (tester) async {
    await pumpReview(tester, size: const Size(900, 2400));

    expect(find.text('Top Over Budget'), findsOneWidget);
    expect(find.text('Top Under Budget'), findsOneWidget);
    final overRect = tester.getRect(find.text('Top Over Budget'));
    final underRect = tester.getRect(find.text('Top Under Budget'));
    expect(overRect.center.dx, lessThan(underRect.center.dx));
    expect(overRect.top, underRect.top);
    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    // The L2 page never repeats the home screen's unbudgeted alert list.
    expect(find.text('Unbudgeted Spend Alerts'), findsNothing);
    expect(find.text('Medical'), findsNothing);

    await tester.tap(find.text('Dining'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetCategoryDetailScreen), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowLeft), findsWidgets);
  });

  testWidgets('rejects a note over 500 characters locally and keeps the draft',
      (tester) async {
    final service = await pumpReview(tester);
    final tooLong = 'a' * 501;

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), tooLong);
    await tester.pump();
    expect(find.text('501/500'), findsOneWidget);

    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(service.saveCalls, 0);
    expect(find.textContaining('500 characters'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      tooLong,
    );
  });

  testWidgets('accepts a note of exactly 500 characters', (tester) async {
    final service = await pumpReview(tester);
    final atLimit = 'a' * 500;

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), atLimit);
    await tester.pump();
    expect(find.text('500/500'), findsOneWidget);

    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(service.saveCalls, 1);
    expect(service.savedNote, atLimit);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('saves a valid note and shows it read-only', (tester) async {
    final service = await pumpReview(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Car repair');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(service.savedNote, 'Car repair');
    expect(find.text('Review note saved'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Car repair'), findsOneWidget);
  });

  testWidgets('saving an empty note deletes it', (tester) async {
    final service = await pumpReview(tester, summary: buildSummary(note: 'Car repair'));
    expect(find.text('Car repair'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  ');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(service.savedNote, '');
    expect(find.text('Car repair'), findsNothing);
    expect(
      find.text(
        'Add a brief note on why this month varied (max 500 chars)...',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps the draft and shows the localized error',
      (tester) async {
    await pumpReview(
      tester,
      saveResult: const Result.failure(LedgerErrorCode.unknownEvent, 'boom'),
    );

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Car repair');
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Car repair',
    );
  });

  testWidgets('hides the trend block when fewer than two months have data',
      (tester) async {
    await pumpReview(
      tester,
      summary: buildSummary(
        trend: const [
          BudgetTrendPoint(
            month: YearMonth(2026, 4),
            budgetMinor: null,
            actualMinor: 0,
            pendingMinor: 0,
            hasReviewNote: true,
          ),
          BudgetTrendPoint(
            month: may,
            budgetMinor: 20000,
            actualMinor: 24000,
            pendingMinor: 0,
            hasReviewNote: false,
          ),
        ],
      ),
    );

    expect(find.text('6-Month Budget vs Actual'), findsNothing);
    expect(find.text('All actual spend'), findsNothing);
  });

  testWidgets('renders the trend with two valid months and the 240/200 bars '
      'stay primary', (tester) async {
    await pumpReview(tester);

    expect(find.text('6-Month Budget vs Actual'), findsOneWidget);
    expect(find.text('All actual spend'), findsOneWidget);
    expect(find.text('Total budget'), findsOneWidget);
  });

  testWidgets('renders in dark mode', (tester) async {
    await pumpReview(tester, brightness: Brightness.dark);

    expect(find.text('Monthly Review & Trends'), findsOneWidget);
    expect(find.text('Committed baseline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays readable at 400x700 with large text', (tester) async {
    await pumpReview(
      tester,
      size: const Size(400, 700),
      textScale: 2.0,
    );

    expect(find.text('Monthly Review & Trends'), findsOneWidget);
    expect(find.text('Committed baseline'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.text('Month review note'), 300);
    expect(find.text('Month review note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
