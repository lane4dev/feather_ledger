import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_state.dart';

/// What counts as "due" (spec 004, US2 / T038).
///
/// The list the user acts on, so the boundary cases are worth pinning: an
/// instance dated today is due, an overdue one is very much due, and one
/// already decided is not.
void main() {
  final today = DateTime(2026, 9, 22);

  ScheduledTransactionEntity instance({
    required String id,
    required DateTime date,
    ScheduledTransactionStatus status = ScheduledTransactionStatus.scheduled,
  }) =>
      ScheduledTransactionEntity(
        id: id,
        seriesId: 'series_1',
        date: date,
        amountMinor: 50000,
        status: status,
      );

  test('includes instances dated today', () {
    final due = dueScheduledInstances(
      [instance(id: 'a', date: DateTime(2026, 9, 22))],
      today: today,
    );

    expect(due.map((i) => i.id), ['a']);
  });

  test('includes overdue instances', () {
    // The one the user most needs to see — a bill that slipped past.
    final due = dueScheduledInstances(
      [instance(id: 'a', date: DateTime(2026, 1, 1))],
      today: today,
    );

    expect(due.map((i) => i.id), ['a']);
  });

  test('excludes future instances', () {
    final due = dueScheduledInstances(
      [instance(id: 'a', date: DateTime(2026, 9, 23))],
      today: today,
    );

    expect(due, isEmpty);
  });

  test('excludes instances already decided', () {
    final due = dueScheduledInstances(
      [
        instance(
            id: 'posted',
            date: DateTime(2026, 9, 1),
            status: ScheduledTransactionStatus.posted),
        instance(
            id: 'skipped',
            date: DateTime(2026, 9, 2),
            status: ScheduledTransactionStatus.skipped),
        instance(
            id: 'scheduled', date: DateTime(2026, 9, 3)),
      ],
      today: today,
    );

    expect(due.map((i) => i.id), ['scheduled']);
  });

  test('orders oldest first', () {
    final due = dueScheduledInstances(
      [
        instance(id: 'newer', date: DateTime(2026, 9, 20)),
        instance(id: 'oldest', date: DateTime(2026, 3, 1)),
        instance(id: 'middle', date: DateTime(2026, 6, 1)),
      ],
      today: today,
    );

    expect(due.map((i) => i.id), ['oldest', 'middle', 'newer']);
  });

  test('ignores the time of day on the cutoff', () {
    // `today` carries no time here, but a caller passing DateTime.now() would
    // hand one over — an instance dated this morning must still be due.
    final withTime = DateTime(2026, 9, 22, 23, 58);
    final due = dueScheduledInstances(
      [instance(id: 'a', date: DateTime(2026, 9, 22, 9, 0))],
      today: withTime,
    );

    expect(due.map((i) => i.id), ['a']);
  });
}
