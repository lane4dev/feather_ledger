import 'package:feather_ledger/core/domain/enums.dart';

/// The decision a catch-up makes about one due bill.
sealed class AutoPostDecision {
  const AutoPostDecision();
}

/// Post it now.
class PostBill extends AutoPostDecision {
  const PostBill();
}

/// Eligible, but inside a pending restore's confirmation window — leave it
/// scheduled and wait for the user to confirm or reject the batch.
class AwaitConfirmation extends AutoPostDecision {
  const AwaitConfirmation();
}

/// Latch it permanently manual: it never auto-posts, now or after the switch
/// or its currency comes back.
class ManualBill extends AutoPostDecision {
  const ManualBill();
}

/// The one place that knows a bill's auto-post eligibility (spec 006,
/// "bill eligibility").
///
/// Pure by design: it receives plain facts and returns a verdict, so the
/// tests are an assertion table and nothing in here touches the database.
/// The callers own the effects — `markAutoPostIneligible`, the actual post,
/// reading the restore-candidate flag, reading/writing the last wall clock.
class AutomaticPostingPolicy {
  const AutomaticPostingPolicy();

  /// The core predicate: may this bill auto-post right now?
  ///
  /// The mode's switch must be on and the bill's due time must be *strictly*
  /// after both the last time that switch turned on and the last time its
  /// currency became current — "already due", or due the same millisecond, is
  /// manual. A previously latched bill stays latched.
  ///
  /// This is the predicate restore-confirmation uses directly: there, a bill
  /// whose currency is away still counts as eligible because leaving a
  /// currency keeps pending-confirmation eligibility (spec 006, US65).
  bool isEligible({
    required RecurringSeriesMode? mode,
    required bool switchEnabled,
    required DateTime? enabledSince,
    required DateTime? currencyActiveSince,
    required DateTime due,
    required bool latchedManual,
  }) {
    if (mode == null) return false;
    return switchEnabled &&
        (enabledSince == null || due.isAfter(enabledSince)) &&
        (currencyActiveSince == null || due.isAfter(currencyActiveSince)) &&
        !latchedManual;
  }

  /// The catch-up settle decision for one due bill.
  ///
  /// Order matters: the restore window is checked *before* the away-currency
  /// latch, because leaving a currency keeps pending-confirmation eligibility
  /// (spec 006, US65) — an away-currency bill inside a window waits, it is
  /// not latched. A bill whose switch is off falls through to manual even
  /// inside a window, because the barrier only preserves bills that are still
  /// eligible (spec 006, US65).
  AutoPostDecision decideCatchUp({
    required RecurringSeriesMode? mode,
    required bool switchEnabled,
    required DateTime? enabledSince,
    required DateTime? currencyActiveSince,
    required String? billCurrency,
    required String currentCurrency,
    required DateTime due,
    required bool latchedManual,
    required bool insideRestoreWindow,
  }) {
    final eligible = isEligible(
      mode: mode,
      switchEnabled: switchEnabled,
      enabledSince: enabledSince,
      currencyActiveSince: currencyActiveSince,
      due: due,
      latchedManual: latchedManual,
    );
    if (eligible && insideRestoreWindow) return const AwaitConfirmation();
    // Away currency: auto-post pauses for any currency the user is not
    // currently looking at, and a bill that fell due while its currency was
    // away never retro-posts (spec 006, US33/34).
    if (billCurrency != currentCurrency) return const ManualBill();
    return eligible ? const PostBill() : const ManualBill();
  }

  /// Whether an edit latches the bill permanently manual (spec 006, US32).
  ///
  /// A real change latches when the new date is in the past, when the wall
  /// clock rolled back (due/not-due ordering is unreliable), or when the bill
  /// was already due — *unless* that last case is only a reschedule of a
  /// restore candidate into the future, which keeps its pending-confirmation
  /// eligibility (spec 006, US66). A no-op save never latches.
  bool editShouldLatch({
    required bool actuallyChanged,
    required bool wasDue,
    required bool movedToPast,
    required bool rollback,
    required bool rescheduledToFutureOnly,
  }) {
    return actuallyChanged &&
        (movedToPast || rollback || (wasDue && !rescheduledToFutureOnly));
  }
}
