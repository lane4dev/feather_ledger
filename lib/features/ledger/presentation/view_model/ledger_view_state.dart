import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import '../../domain/value_objects/account_balance.dart';

class LedgerViewState {
  final DateTime selectedDate;
  /// Already written out — the state carries what the screen prints, not the
  /// numbers it would have to convert.
  final AsyncValue<MonthlySummaryUiModel> summary;
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
    AsyncValue<MonthlySummaryUiModel>? summary,
    Map<String, AsyncValue<AccountBalance>>? accountBalances,
  }) {
    return LedgerViewState(
      selectedDate: selectedDate ?? this.selectedDate,
      summary: summary ?? this.summary,
      accountBalances: accountBalances ?? this.accountBalances,
    );
  }
}
