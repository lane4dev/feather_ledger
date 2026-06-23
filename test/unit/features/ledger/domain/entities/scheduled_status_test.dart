import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

/// The `status` column of `scheduled_transactions_view` is plain TEXT, so the
/// codec is the only thing keeping writers and readers aligned (spec 004,
/// FR-013).
void main() {
  test('toStorage / decodeScheduledStatus round-trip every value', () {
    for (final status in ScheduledTransactionStatus.values) {
      expect(
        decodeScheduledStatus(status.toStorage()),
        status,
        reason: '${status.name} does not survive a storage round-trip',
      );
    }
  });

  test('toStorage writes the bare enum name, not the toString form', () {
    expect(ScheduledTransactionStatus.posted.toStorage(), 'posted');
    // The regression this guards: `toString().split('.').last` happened to
    // produce the same string, so a change to that idiom would silently
    // change every stored value.
    expect(
      ScheduledTransactionStatus.posted.toStorage(),
      isNot(contains('.')),
    );
  });

  test('an unrecognised stored status degrades to scheduled, never throws',
      () {
    // 'pending' is the value the table's own doc comment names, so it is the
    // realistic bad row. Decoding used to have no `orElse` in two of the four
    // call sites and would take down whatever screen listed the instance.
    expect(decodeScheduledStatus('pending'),
        ScheduledTransactionStatus.scheduled);
    expect(decodeScheduledStatus(''), ScheduledTransactionStatus.scheduled);
    expect(decodeScheduledStatus('POSTED'),
        ScheduledTransactionStatus.scheduled);
  });
}
