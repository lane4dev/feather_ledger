import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value_objects/account_balance.dart';

/// What the ledger screen holds across tab switches: which month is on
/// screen, and the per-account balances the picker reads.
///
/// The month's headline figures are *not* here. They were, as an
/// [AsyncValue] the view model kept alive by hand — and a hand-held
/// subscription cannot tell when one of its inputs moves. See
/// [ledgerMonthlySummaryProvider].
class LedgerViewState {
  final DateTime selectedDate;
  final Map<String, AsyncValue<AccountBalance>> accountBalances;

  const LedgerViewState({
    required this.selectedDate,
    required this.accountBalances,
  });

  factory LedgerViewState.initial({DateTime? selectedDate}) {
    final now = selectedDate ?? DateTime.now();
    return LedgerViewState(
      selectedDate: DateTime(now.year, now.month, now.day),
      accountBalances: const {},
    );
  }

  LedgerViewState copyWith({
    DateTime? selectedDate,
    Map<String, AsyncValue<AccountBalance>>? accountBalances,
  }) {
    return LedgerViewState(
      selectedDate: selectedDate ?? this.selectedDate,
      accountBalances: accountBalances ?? this.accountBalances,
    );
  }
}
