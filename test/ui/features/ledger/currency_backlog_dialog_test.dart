import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/currency_backlog_dialog.dart';

import '../../../support/fakes/recording_services.dart';

const _cash = AccountEntity(
  id: 'acc_cash',
  name: 'Cash',
  type: AccountType.cash,
  currencyCode: 'USD',
  balanceMinor: 0,
  archived: false,
  lastUpdatedEventId: 0,
);

ScheduledTransactionEntity _bill(String id) => ScheduledTransactionEntity(
      id: id,
      seriesId: 'series_1',
      occurrenceKey: 'series_1_$id',
      scheduledDate: DateTime(2026, 11, 1),
      status: ScheduledTransactionStatus.scheduled,
      manualOnly: false,
      recurringTransactionSeries: RecurringTransactionSeriesEntity(
        id: 'series_1',
        description: 'Rent',
        amountMinor: 50000,
        type: RecurringSeriesKind.expense,
        categoryId: 'cat_rent',
        accountId: _cash.id,
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 1),
        autoPost: true,
        mode: RecurringSeriesMode.repeating,
      ),
      kind: TransactionKind.expense,
      account: _cash,
    );

/// A service whose backlog is fixed and whose settle choice is recorded.
class _BacklogService extends RecordingRecurringService {
  _BacklogService(this.backlog);
  final List<ScheduledTransactionEntity> backlog;
  final List<bool> settledPostAll = [];

  @override
  Future<List<ScheduledTransactionEntity>> getCurrencyBacklog(
          String currencyCode) async =>
      backlog;

  @override
  Future<int> settleCurrencyBacklog(String currencyCode,
          {required bool postAll}) async {
    settledPostAll.add(postAll);
    return postAll ? backlog.length : 0;
  }
}

Widget _pump(_BacklogService service) => ProviderScope(
      overrides: [
        recurringServiceProvider.overrideWith((ref) => service),
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
          body: Builder(
            builder: (context) => Center(
              child: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showCurrencyBacklogDialog(context, ref, 'USD'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

/// The currency-switch-back two-way offer (spec 006, US49).
///
/// The dialog only asks when there is a real backlog; "post all" and "keep
/// pending" are the two honest answers, and each reaches the service with its
/// choice rather than a verdict the dialog made up.
void main() {
  testWidgets('offers both answers and posts all on "post all"',
      (tester) async {
    final service = _BacklogService([_bill('a'), _bill('b'), _bill('c')]);
    await tester.pumpWidget(_pump(service));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Due auto-posting bills in \$ (Dollar)'), findsOneWidget);
    expect(
        find.text('3 auto-posting bills became due while using '
            'another currency.'),
        findsOneWidget);

    await tester.tap(find.text('Post all'));
    await tester.pumpAndSettle();

    expect(service.settledPostAll, [true]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('freezes the backlog on "keep pending"', (tester) async {
    final service = _BacklogService([_bill('a')]);
    await tester.pumpWidget(_pump(service));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep as pending'));
    await tester.pumpAndSettle();

    expect(service.settledPostAll, [false]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('does not ask when there is no backlog', (tester) async {
    final service = _BacklogService(const []);
    await tester.pumpWidget(_pump(service));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(service.settledPostAll, isEmpty);
  });
}
