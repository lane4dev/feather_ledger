import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/ledger_service.dart';
import '../../domain/value_objects/monthly_summary.dart';

import '../mappers/transaction_ui_mapper.dart';
import '../models/transaction_tile_ui_model.dart';

import 'ledger_view_state.dart';

part 'ledger_view_model.g.dart';

@Riverpod(keepAlive: true)
class LedgerViewModel extends _$LedgerViewModel {
  StreamSubscription<List<TransactionEntity>>? _transactionsSub;
  StreamSubscription<MonthlySummary>? _summarySub;
  StreamSubscription<List<ScheduledTransactionEntity>>? _scheduledSub;

  @override
  LedgerViewState build() {
    final initial = LedgerViewState.initial();

    ref.onDispose(() {
      _transactionsSub?.cancel();
      _summarySub?.cancel();
      _scheduledSub?.cancel();
    });

    _subscribeForMonth(initial.selectedDate);
    _subscribeScheduledTransactions();
    return initial;
  }

  void setMonth(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == state.selectedDate) return;

    state = state.copyWith(
      selectedDate: normalized,
      summary: const AsyncLoading(),
      transactions: const AsyncLoading(),
      dailyTransactions: const AsyncLoading(),
    );

    _subscribeForMonth(normalized);
  }

  Future<void> ensureAccountBalanceLoaded(String accountId) async {
    final existing = state.accountBalances[accountId];
    if (existing is AsyncLoading || existing is AsyncData) return;
    await refreshAccountBalance(accountId);
  }

  Future<void> refreshAccountBalance(String accountId) async {
    state = state.copyWith(
      accountBalances: {
        ...state.accountBalances,
        accountId: const AsyncLoading(),
      },
    );

    try {
      final balance = await ref.read(ledgerServiceProvider).accountBalance(
            accountId,
          );
      state = state.copyWith(
        accountBalances: {
          ...state.accountBalances,
          accountId: AsyncData(balance),
        },
      );
    } catch (e, st) {
      state = state.copyWith(
        accountBalances: {
          ...state.accountBalances,
          accountId: AsyncError(e, st),
        },
      );
    }
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return ref.read(ledgerServiceProvider).addTransaction(
          amount: amount,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        );
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return ref.read(ledgerServiceProvider).updateTransaction(
          id: id,
          amount: amount,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        );
  }

  Future<void> deleteTransaction(String id) {
    return ref.read(ledgerServiceProvider).deleteTransaction(id);
  }

  void _subscribeScheduledTransactions() {
    _scheduledSub ??=
        ref.read(ledgerServiceProvider).watchScheduledTransactions().listen(
      (items) {
        state = state.copyWith(
          scheduledTransactions: AsyncData(items),
        );
      },
      onError: (Object error, StackTrace st) {
        state = state.copyWith(
          scheduledTransactions: AsyncError(error, st),
        );
      },
    );
  }

  void _subscribeForMonth(DateTime datetime) {
    _transactionsSub?.cancel();
    _summarySub?.cancel();

    final service = ref.read(ledgerServiceProvider);
    const mapper = TransactionUiMapper();

    _transactionsSub = service.watchTransactions(datetime).listen(
      (items) {
        final uiItems = items.map(mapper.toTile).toList();
        state = state.copyWith(
          transactions: AsyncData(uiItems),
          dailyTransactions: AsyncData(_groupByDay(uiItems)),
        );
      },
      onError: (Object error, StackTrace st) {
        state = state.copyWith(
          transactions: AsyncError(error, st),
          dailyTransactions: AsyncError(error, st),
        );
      },
    );

    _summarySub = service.watchMonthlySummary(datetime).listen(
      (summary) {
        state = state.copyWith(summary: AsyncData(summary));
      },
      onError: (Object error, StackTrace st) {
        state = state.copyWith(summary: AsyncError(error, st));
      },
    );
  }

  Map<DateTime, List<TransactionTileUiModel>> _groupByDay(
    List<TransactionTileUiModel> transactions,
  ) {
    final grouped = <DateTime, List<TransactionTileUiModel>>{};
    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }
    return grouped;
  }
}
