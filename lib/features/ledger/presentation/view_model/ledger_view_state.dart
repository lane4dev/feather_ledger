import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/queries/watch_monthly_snapshot_query.dart';
import '../../domain/value_objects/account_balance.dart';

class LedgerViewState {
  final DateTime selectedDate;
  final AsyncValue<MonthlySnapshotTotals> summary;
  final AsyncValue<List<ScheduledTransactionEntity>> scheduledTransactions;
  final Map<String, AsyncValue<AccountBalance>> accountBalances;

  const LedgerViewState({
    required this.selectedDate,
    required this.summary,
    required this.scheduledTransactions,
    required this.accountBalances,
  });

  factory LedgerViewState.initial({DateTime? selectedDate}) {
    final now = selectedDate ?? DateTime.now();
    return LedgerViewState(
      selectedDate: DateTime(now.year, now.month, now.day),
      summary: const AsyncLoading(),
      scheduledTransactions: const AsyncLoading(),
      accountBalances: const {},
    );
  }

  LedgerViewState copyWith({
    DateTime? selectedDate,
    AsyncValue<MonthlySnapshotTotals>? summary,
    AsyncValue<List<ScheduledTransactionEntity>>? scheduledTransactions,
    Map<String, AsyncValue<AccountBalance>>? accountBalances,
  }) {
    return LedgerViewState(
      selectedDate: selectedDate ?? this.selectedDate,
      summary: summary ?? this.summary,
      scheduledTransactions:
          scheduledTransactions ?? this.scheduledTransactions,
      accountBalances: accountBalances ?? this.accountBalances,
    );
  }
}
