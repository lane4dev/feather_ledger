import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';

part 'watch_monthly_pending_bills_query.g.dart';

/// The ledger's calendar-month pending list, including read-time virtual
/// occurrences for the same 24-month horizon the budget uses.
///
/// Virtual expansion is deliberately bounded: before the current month the
/// list must stay historical, and past `nowYm + 24` only physically
/// materialized rows are shown. The physical materialization window itself is
/// unchanged.
class WatchMonthlyPendingBillsQuery {
  final RecurringRepository _repository;
  final DomainClock _clock;

  WatchMonthlyPendingBillsQuery(this._repository, this._clock);

  Stream<List<ScheduledTransactionEntity>> execute({
    required DateTime month,
    required String currencyCode,
  }) {
    final includeVirtual = RecurrenceExpander.isWithinVirtualPendingHorizon(
      year: month.year,
      month: month.month,
      now: _clock.now(),
    );

    return _repository.watchMonthlyPendingBills(
      currencyCode: currencyCode,
      year: month.year,
      month: month.month,
      includeVirtual: includeVirtual,
    );
  }
}

@riverpod
WatchMonthlyPendingBillsQuery watchMonthlyPendingBillsQuery(Ref ref) {
  return WatchMonthlyPendingBillsQuery(
    ref.watch(recurringRepositoryProvider),
    ref.watch(ledgerClockProvider),
  );
}
