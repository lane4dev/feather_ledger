import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/queries/watch_monthly_snapshot_query.dart';
import '../../domain/value_objects/account_balance.dart';

class LedgerViewState {
  final DateTime selectedDate;
  final AsyncValue<MonthlySnapshotTotals> summary;
  final Map<String, AsyncValue<AccountBalance>> accountBalances;

  const LedgerViewState({
    required this.selectedDate,
    required this.summary,
    required this.accountBalances,
  });

  factory LedgerViewState.initial({DateTime? selectedDate}) {
    final now = selectedDate ?? DateTime.now();
    return LedgerViewState(
      selectedDate: DateTime(now.year, now.month, now.day),
      summary: const AsyncLoading(),
      accountBalances: const {},
    );
  }

  LedgerViewState copyWith({
    DateTime? selectedDate,
    AsyncValue<MonthlySnapshotTotals>? summary,
    Map<String, AsyncValue<AccountBalance>>? accountBalances,
  }) {
    return LedgerViewState(
      selectedDate: selectedDate ?? this.selectedDate,
      summary: summary ?? this.summary,
      accountBalances: accountBalances ?? this.accountBalances,
    );
  }
}
