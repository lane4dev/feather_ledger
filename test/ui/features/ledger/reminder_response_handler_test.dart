import 'dart:async';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_transaction_history_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/notifications/reminder_response_handler.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const account = AccountEntity(
    id: 'a',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 10000,
    archived: false,
    lastUpdatedEventId: 0);
const category = CategoryEntity(
    id: 'c',
    name: 'Food',
    iconKey: '1',
    colorInt: 0xff000000,
    type: CategoryType.expense);

class _Reminders implements RecurringReminders {
  final changed = StreamController<void>.broadcast();
  final queued = <NotificationResponse>[];
  bool deferred = false;
  @override
  Stream<void> get responsesChanged => changed.stream;
  @override
  List<NotificationResponse> takeResponses() {
    final copy = queued.toList();
    queued.clear();
    return copy;
  }

  @override
  bool takeDeferredAutoPostCatchUp() {
    final value = deferred;
    deferred = false;
    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Recurring implements RecurringService {
  _Recurring(this.bill,
      {this.failSkip = false, Map<String, ScheduledBillRedirect>? redirects})
      : redirects = redirects ?? {};
  ScheduledTransactionEntity bill;
  final bool failSkip;
  final Map<String, ScheduledBillRedirect> redirects;
  final calls = <String>[];
  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduled(
          {String? currencyCode}) =>
      Stream.value([bill]);
  @override
  Future<ScheduledBillRedirect?> resolveScheduledRedirect(String oldId) async =>
      redirects[oldId];
  @override
  Future<Result<void>> postInstance(String id, {String? commandId}) async {
    calls.add('post');
    bill = bill.copyWith(
        status: ScheduledTransactionStatus.posted, transactionId: 'tx');
    return unitResult;
  }

  @override
  Future<Result<void>> deleteBill(String id,
      {required RecurringScope scope}) async {
    calls.add('skip');
    expect(scope, RecurringScope.thisOnly);
    if (failSkip) {
      return const Failure(LedgerErrorCode.categoryArchived, 'failed');
    }
    bill = bill.copyWith(status: ScheduledTransactionStatus.skipped);
    return unitResult;
  }

  @override
  Future<void> catchUpAutoPosted({String? accountId}) async {
    calls.add('catchup');
    if (bill.status == ScheduledTransactionStatus.scheduled) {
      bill = bill.copyWith(
          status: ScheduledTransactionStatus.posted, transactionId: 'tx');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CurrencyRecorder implements CurrencyController {
  final setCalls = <String>[];
  @override
  Future<String> build() async => 'CNY';
  @override
  Future<void> setCurrency(String currencyCode) async {
    setCalls.add(currencyCode);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Ledger implements LedgerService {
  _Ledger(this.date);
  final DateTime date;
  TransactionEntity get _transaction => TransactionEntity(
      id: 'tx',
      amount: -100,
      type: TransactionKind.expense,
      date: date,
      account: account,
      category: category,
      eventId: 1);
  @override
  Stream<List<TransactionEntity>> watchTransactions(DateTime month,
          {String? currencyCode}) =>
      Stream.value([_transaction]);
  @override
  Future<TransactionEntity?> getTransactionBySourceBill(
          String sourceScheduledBillId) async =>
      _transaction;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<({_Reminders reminders, _Recurring recurring})> pump(
      WidgetTester tester,
      {String? action,
      bool deferred = false,
      bool failSkip = false,
      bool initialResponse = true,
      bool alreadyPosted = false,
      CurrencyController? currency,
      String payloadId = 'bill',
      Map<String, ScheduledBillRedirect> redirects = const {}}) async {
    final when = DateTime(2026, 11, 15, 12);
    final bill = ScheduledTransactionEntity(
        id: 'bill',
        seriesId: 'series',
        amountMinor: 100,
        date: when,
        account: account,
        category: category,
        kind: TransactionKind.expense);
    final recurring = _Recurring(
        alreadyPosted
            ? bill.copyWith(
                status: ScheduledTransactionStatus.posted, transactionId: 'tx')
            : bill,
        failSkip: failSkip,
        redirects: redirects);
    final reminders = _Reminders()..deferred = deferred;
    if (initialResponse) {
      reminders.queued.add(NotificationResponse(
          notificationResponseType: action == null
              ? NotificationResponseType.selectedNotification
              : NotificationResponseType.selectedNotificationAction,
          payload: '${RecurringReminders.payloadPrefix}$payloadId',
          actionId: action));
    }
    final router = GoRouter(
        initialLocation: initialResponse ? '/ledger' : '/more',
        routes: [
          GoRoute(
              path: '/more',
              builder: (_, __) => const Scaffold(body: Text('More'))),
          GoRoute(
              path: '/ledger',
              builder: (_, __) => const Scaffold(body: Text('Ledger'))),
        ]);
    addTearDown(router.dispose);
    addTearDown(reminders.changed.close);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          goRouterProvider.overrideWithValue(router),
          recurringRemindersProvider.overrideWithValue(reminders),
          recurringServiceProvider.overrideWithValue(recurring),
          ledgerServiceProvider.overrideWithValue(_Ledger(when)),
          displayCurrencySymbolProvider.overrideWithValue('\$'),
          getTransactionHistoryProvider.overrideWith((ref, id) async => []),
          if (currency != null) currencyControllerProvider.overrideWith(() => currency),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ReminderResponseHandler(child: child!),
        )));
    await tester.pumpAndSettle();
    return (reminders: reminders, recurring: recurring);
  }

  testWidgets('cold notification tap opens the pending bill', (tester) async {
    await pump(tester);
    expect(find.byType(PendingBillSheet), findsOneWidget);
  });

  testWidgets('notification tap opens an already posted transaction',
      (tester) async {
    await pump(tester, alreadyPosted: true);
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
  });

  testWidgets('foreground notification opens the bill from another page',
      (tester) async {
    final state = await pump(tester, initialResponse: false);
    expect(find.text('More'), findsOneWidget);
    state.reminders.queued.add(const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '${RecurringReminders.payloadPrefix}bill'));
    state.reminders.changed.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(PendingBillSheet), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);
  });

  testWidgets('a stale post action never records the bill twice',
      (tester) async {
    final state = await pump(tester,
        action: RecurringReminders.postAction, alreadyPosted: true);
    expect(state.recurring.calls, isEmpty);
    expect(state.recurring.bill.status, ScheduledTransactionStatus.posted);
    expect(find.text('This bill is no longer available.'), findsOneWidget);
  });

  testWidgets('skip is processed before deferred subscription catch-up',
      (tester) async {
    final state = await pump(tester,
        action: RecurringReminders.skipAction, deferred: true);
    expect(state.recurring.calls, ['skip', 'catchup']);
    expect(state.recurring.bill.status, ScheduledTransactionStatus.skipped);
    expect(find.text('Bill skipped'), findsOneWidget);
  });

  testWidgets('failed skip does not trigger deferred auto-post',
      (tester) async {
    final state = await pump(tester,
        action: RecurringReminders.skipAction, deferred: true, failSkip: true);
    expect(state.recurring.calls, ['skip']);
    expect(state.recurring.bill.status, ScheduledTransactionStatus.scheduled);
  });

  testWidgets('post records the bill and opens its transaction details',
      (tester) async {
    final state = await pump(tester,
        action: RecurringReminders.postAction, deferred: true);
    expect(state.recurring.calls, ['post', 'catchup']);
    expect(state.recurring.bill.status, ScheduledTransactionStatus.posted);
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
  });

  testWidgets('posting an old-currency notification never changes the setting',
      (tester) async {
    final recorder = _CurrencyRecorder();
    final state = await pump(tester,
        action: RecurringReminders.postAction, currency: recorder);
    expect(state.recurring.calls, ['post']);
    expect(state.recurring.bill.status, ScheduledTransactionStatus.posted);
    expect(recorder.setCalls, isEmpty);
  });

  testWidgets('a notification shown before a reschedule opens the new bill',
      (tester) async {
    await pump(tester,
        payloadId: 'old',
        redirects: {
          'old': const ScheduledBillRedirect(oldId: 'old', newId: 'bill'),
        });
    expect(find.byType(PendingBillSheet), findsOneWidget);
  });

  testWidgets('a deleted bill reports deleted, not unavailable', (tester) async {
    await pump(tester,
        payloadId: 'old',
        redirects: {'old': const ScheduledBillRedirect(oldId: 'old')});
    expect(find.text('This bill has been deleted.'), findsOneWidget);
    expect(find.text('This bill is no longer available.'), findsNothing);
  });
}
