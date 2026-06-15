import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/queries/watch_monthly_snapshot_query.dart';
import '../../domain/services/ledger_service.dart';

import '../mappers/transaction_ui_mapper.dart';
import '../models/transaction_tile_ui_model.dart';

import 'ledger_view_state.dart';

part 'ledger_view_model.g.dart';

@riverpod
Stream<Map<DateTime, List<TransactionTileUiModel>>> ledgerMonthlyTransactions(
  Ref ref,
  DateTime month,
) {
  final service = ref.watch(ledgerServiceProvider);
  const mapper = TransactionUiMapper();

  return service.watchTransactions(month).map((items) {
    final uiItems = items.map(mapper.toTile).toList();
    return groupTransactionsByDay(uiItems);
  });
}

Map<DateTime, List<TransactionTileUiModel>> groupTransactionsByDay(
  List<TransactionTileUiModel> transactions,
) {
  final grouped = <DateTime, List<TransactionTileUiModel>>{};
  for (final tx in transactions) {
    final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    grouped.putIfAbsent(dateKey, () => []).add(tx);
  }
  return grouped;
}

@Riverpod(keepAlive: true)
class LedgerViewModel extends _$LedgerViewModel {
  StreamSubscription<MonthlySnapshotTotals>? _summarySub;
  StreamSubscription<List<ScheduledTransactionEntity>>? _scheduledSub;

  @override
  LedgerViewState build() {
    final initial = LedgerViewState.initial();

    ref.onDispose(() {
      _summarySub?.cancel();
      _scheduledSub?.cancel();
    });

    _subscribeSummary(initial.selectedDate);
    _subscribeScheduledTransactions();
    return initial;
  }

  void setMonth(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == state.selectedDate) return;

    state = state.copyWith(
      selectedDate: normalized,
    );

    _subscribeSummary(normalized);
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

  Future<Result<void>> addTransaction({
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return ref.read(ledgerServiceProvider).addTransaction(
          commandId: const Uuid().v4(),
          amountMinor: amountMinor,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        );
  }

  Future<Result<void>> updateTransaction({
    required String id,
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) {
    return ref.read(ledgerServiceProvider).updateTransaction(
          commandId: const Uuid().v4(),
          id: id,
          amountMinor: amountMinor,
          type: type,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          note: note,
        );
  }

  Future<Result<void>> deleteTransaction(String id) {
    return ref
        .read(ledgerServiceProvider)
        .deleteTransaction(id, commandId: const Uuid().v4());
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

  void _subscribeSummary(DateTime datetime) {
    _summarySub?.cancel();

    _summarySub =
        ref
            .read(ledgerServiceProvider)
            .watchMonthlySnapshot(
              datetime,
              currencyCode: ref.read(currencyControllerProvider).value ??
                  AppCurrencies.defaultCurrency.code,
            )
            .listen(
      (summary) {
        state = state.copyWith(summary: AsyncData(summary));
      },
      onError: (Object error, StackTrace st) {
        state = state.copyWith(summary: AsyncError(error, st));
      },
    );
  }
}
