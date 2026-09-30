import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'restore_skipped_bill_command.g.dart';

/// Restores a `skipped` bill occurrence back to `scheduled` pending state.
///
/// Rejects stopped rules, missing/archived accounts, and non-skipped rows.
/// If the series has `autoPost == true` and the bill's effective date is
/// already due (`<= now`), sets `manualOnly = true` so the restored bill stays
/// in pending for manual confirmation instead of silently auto-posting.
class RestoreSkippedBillCommand {
  final RecurringRepository _recurringRepository;
  final DomainClock _clock;

  RestoreSkippedBillCommand(
    this._recurringRepository, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  Future<void> execute(String scheduledId) {
    return _recurringRepository.restoreSkippedBill(
      scheduledId,
      now: _clock.now(),
    );
  }
}

@riverpod
RestoreSkippedBillCommand restoreSkippedBillCommand(Ref ref) {
  return RestoreSkippedBillCommand(ref.watch(recurringRepositoryProvider));
}
