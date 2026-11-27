import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_pending_bills_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/mappers/transaction_ui_mapper.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_transaction_list.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'CNY';
}

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets(
      'tapping a virtual ledger bill materializes it once and opens '
      'the pending bill sheet', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2026, 5, 15, 10);
    final month = DateTime(2026, 7);
    final harness = LedgerServiceHarness(clock: FixedClock(now));
    addTearDown(harness.close);

    late ScheduledTransactionEntity virtualBill;
    await tester.runAsync(() async {
      await harness.seedAccount(
        id: 'acc-cash',
        name: 'Cash',
        currencyCode: 'CNY',
      );
      await harness.categoryService.createCategory(
        commandId: 'cat-dining',
        categoryId: 'dining',
        name: 'Dining',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: CategoryType.expense,
      );
      final created = await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 2500,
        accountId: 'acc-cash',
        categoryId: 'dining',
        description: 'Daily lunch',
        frequency: 'DAILY',
        startDate: DateTime(2026, 5, 1, 12),
      );
      expect(created, isA<Success<String>>());

      final bills = await WatchMonthlyPendingBillsQuery(
        harness.recurringRepository,
        FixedClock(now),
      ).execute(month: month, currencyCode: 'CNY').first;
      virtualBill = bills.firstWhere(
        (bill) => bill.isVirtual && bill.occurrenceKey == '2026-07-10',
      );
    });

    const mapper = TransactionUiMapper();
    final tile = mapper.toPendingTile(
      virtualBill,
      category: virtualBill.category!,
      account: virtualBill.account!,
    );
    expect(tile.isVirtual, isTrue);
    expect(tile.occurrenceKey, '2026-07-10');

    final container = ProviderContainer(
      overrides: [
        currencyControllerProvider.overrideWith(_FixedCurrency.new),
        accountListProvider.overrideWith((ref) => Stream.value(const [])),
        recurringServiceProvider.overrideWithValue(harness.recurringService),
        ledgerMonthlyTransactionsProvider(month)
            .overrideWith((ref) => Stream.value(LedgerDayGroup.group(
                  [tile],
                  currencySymbol: '¥',
                ))),
        ledgerMonthlySummaryProvider(month).overrideWith(
          (ref) => Stream.value(
            const MonthlySummaryUiModel(
              displayBalance: '¥0.00',
              displayIncome: '¥0.00',
              displayExpense: '¥0.00',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => LedgerTransactionList(
                month: month,
                currency: '¥',
                l10n: AppLocalizations.of(context)!,
                controller: ScrollController(),
                headerHeight: 280,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Daily lunch'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.byType(PendingBillSheet), findsOneWidget);

    final materialized = await tester.runAsync(
      () => harness.recurringRepository
          .watchMonthlyPendingBills(
            currencyCode: 'CNY',
            year: month.year,
            month: month.month,
            includeVirtual: false,
          )
          .first,
    );
    expect(
      materialized!.where((bill) =>
          bill.seriesId == virtualBill.seriesId &&
          bill.occurrenceKey == '2026-07-10' &&
          !bill.isVirtual),
      hasLength(1),
      reason: 'the physical row exists exactly once',
    );
  });

  testWidgets(
      'rapid double-tap materializes only once and Failure shows SnackBar',
      (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final month = DateTime(2026, 7);
    final now = DateTime(2026, 5, 15, 10);
    final harness = LedgerServiceHarness(clock: FixedClock(now));
    addTearDown(harness.close);

    late TransactionTileUiModel tile;
    await tester.runAsync(() async {
      await harness.seedAccount(
        id: 'acc-cash',
        name: 'Cash',
        currencyCode: 'CNY',
      );
      await harness.categoryService.createCategory(
        commandId: 'cat-dining',
        categoryId: 'dining',
        name: 'Dining',
        iconKey: 'utensils',
        colorInt: 0xFFE65100,
        type: CategoryType.expense,
      );
      await harness.recurringService.createSeries(
        type: RecurringSeriesKind.expense,
        amountMinor: 2500,
        accountId: 'acc-cash',
        categoryId: 'dining',
        description: 'Daily lunch',
        frequency: 'DAILY',
        startDate: DateTime(2026, 5, 1, 12),
      );
      final bills = await harness.ledgerService
          .watchMonthlyPendingBills(month, currencyCode: 'CNY')
          .first;
      final virtualBill = bills.firstWhere(
        (b) => b.isVirtual && b.occurrenceKey == '2026-07-10',
      );
      tile = const TransactionUiMapper().toPendingTile(
        virtualBill,
        category: virtualBill.category!,
        account: virtualBill.account!,
      );
    });

    final completer = Completer<Result<TransactionTileUiModel>>();
    var calls = 0;

    final container = ProviderContainer(
      overrides: [
        currencyControllerProvider.overrideWith(_FixedCurrency.new),
        accountListProvider.overrideWith((ref) => Stream.value(const [])),
        recurringViewModelProvider.overrideWith(
          () => _StubRecurringViewModel(
            onMaterialize: () {
              calls++;
              return completer.future;
            },
          ),
        ),
        ledgerMonthlyTransactionsProvider(month)
            .overrideWith((ref) => Stream.value(LedgerDayGroup.group(
                  [tile],
                  currencySymbol: '¥',
                ))),
        ledgerMonthlySummaryProvider(month).overrideWith(
          (ref) => Stream.value(
            const MonthlySummaryUiModel(
              displayBalance: '¥0.00',
              displayIncome: '¥0.00',
              displayExpense: '¥0.00',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => LedgerTransactionList(
                month: month,
                currency: '¥',
                l10n: AppLocalizations.of(context)!,
                controller: ScrollController(),
                headerHeight: 280,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Two rapid taps while the first materialize is still in flight.
    await tester.tap(find.text('Daily lunch'));
    await tester.tap(find.text('Daily lunch'));
    await tester.pump();
    expect(calls, 1);

    // Complete with Failure -> SnackBar shown, no PendingBillSheet opened.
    completer.complete(
      const Failure(
        LedgerErrorCode.recurringSeriesStopped,
        'Series stopped',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PendingBillSheet), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

class _StubRecurringViewModel extends RecurringViewModel {
  final Future<Result<TransactionTileUiModel>> Function() onMaterialize;

  _StubRecurringViewModel({required this.onMaterialize});

  @override
  Future<Result<TransactionTileUiModel>> materializeVirtualPendingTile({
    required String seriesId,
    required String occurrenceKey,
  }) =>
      onMaterialize();
}
