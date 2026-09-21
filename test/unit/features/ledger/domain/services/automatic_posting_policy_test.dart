import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/services/automatic_posting_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = AutomaticPostingPolicy();
  final due = DateTime(2026, 1, 10);

  group('isEligible', () {
    bool eligible({
      RecurringSeriesMode? mode = RecurringSeriesMode.repeating,
      bool switchEnabled = true,
      DateTime? enabledSince,
      DateTime? currencyActiveSince,
      DateTime? dueAt,
      bool latchedManual = false,
    }) =>
        policy.isEligible(
          mode: mode,
          switchEnabled: switchEnabled,
          enabledSince: enabledSince,
          currencyActiveSince: currencyActiveSince,
          due: dueAt ?? due,
          latchedManual: latchedManual,
        );

    test('is false when the mode switch is off', () {
      expect(eligible(switchEnabled: false), isFalse);
    });

    test('is true when the switch is on and nothing else constrains it', () {
      expect(eligible(), isTrue);
    });

    test('is true when the due time is strictly after the switch boundary', () {
      expect(eligible(enabledSince: due.subtract(const Duration(seconds: 1))),
          isTrue);
    });

    test('is false when the due time equals the switch boundary', () {
      expect(eligible(enabledSince: due), isFalse);
    });

    test('is false when the due time precedes the switch boundary', () {
      expect(eligible(enabledSince: due.add(const Duration(seconds: 1))),
          isFalse);
    });

    test('respects the currency-activation boundary the same way', () {
      expect(
          eligible(
              currencyActiveSince: due.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(eligible(currencyActiveSince: due), isFalse);
      expect(eligible(currencyActiveSince: due.add(const Duration(seconds: 1))),
          isFalse);
    });

    test('is false for a latched (already manual) bill', () {
      expect(eligible(latchedManual: true), isFalse);
    });

    test('is false when the series mode is unknown', () {
      expect(eligible(mode: null), isFalse);
    });
  });

  group('decideCatchUp', () {
    AutoPostDecision decide({
      RecurringSeriesMode? mode = RecurringSeriesMode.repeating,
      bool switchEnabled = true,
      DateTime? enabledSince,
      DateTime? currencyActiveSince,
      String? billCurrency = 'USD',
      String currentCurrency = 'USD',
      DateTime? dueAt,
      bool latchedManual = false,
      bool insideRestoreWindow = false,
    }) =>
        policy.decideCatchUp(
          mode: mode,
          switchEnabled: switchEnabled,
          enabledSince: enabledSince,
          currencyActiveSince: currencyActiveSince,
          billCurrency: billCurrency,
          currentCurrency: currentCurrency,
          due: dueAt ?? due,
          latchedManual: latchedManual,
          insideRestoreWindow: insideRestoreWindow,
        );

    test('posts an eligible bill', () {
      expect(decide(), isA<PostBill>());
    });

    test('waits when the bill is eligible but inside a restore window', () {
      expect(decide(insideRestoreWindow: true), isA<AwaitConfirmation>());
    });

    test('latches a bill whose currency is away', () {
      expect(decide(billCurrency: 'CNY'), isA<ManualBill>());
    });

    test('keeps an away-currency bill waiting when it is inside a window',
        () {
      // Spec 006 US65: leaving a currency keeps pending-confirmation
      // eligibility, so the window check must win over the away-currency latch.
      expect(
          decide(billCurrency: 'CNY', insideRestoreWindow: true),
          isA<AwaitConfirmation>());
    });

    test('latches a bill whose switch is off even inside a window', () {
      expect(decide(switchEnabled: false, insideRestoreWindow: true),
          isA<ManualBill>());
    });

    test('latches a bill that is already manual', () {
      expect(decide(latchedManual: true), isA<ManualBill>());
    });

    test('latches a bill with no series', () {
      expect(decide(mode: null), isA<ManualBill>());
    });
  });

  group('editShouldLatch', () {
    bool latch({
      bool actuallyChanged = true,
      bool wasDue = false,
      bool movedToPast = false,
      bool rollback = false,
      bool rescheduledToFutureOnly = false,
    }) =>
        policy.editShouldLatch(
          actuallyChanged: actuallyChanged,
          wasDue: wasDue,
          movedToPast: movedToPast,
          rollback: rollback,
          rescheduledToFutureOnly: rescheduledToFutureOnly,
        );

    test('is false for a no-op save', () {
      expect(latch(actuallyChanged: false), isFalse);
    });

    test('is true when the new date is in the past', () {
      expect(latch(movedToPast: true), isTrue);
    });

    test('is true on a detected clock rollback', () {
      expect(latch(rollback: true), isTrue);
    });

    test('is true for a real change to an already-due bill', () {
      expect(latch(wasDue: true), isTrue);
    });

    test('is false when a due bill is only rescheduled into the future',
        () {
      expect(latch(wasDue: true, rescheduledToFutureOnly: true), isFalse);
    });

    test('is false for a real change to a still-future bill', () {
      expect(latch(), isFalse);
    });
  });
}
