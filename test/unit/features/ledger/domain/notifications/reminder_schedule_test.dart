import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/notifications/reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 10);
  ScheduledTransactionEntity bill(String id, DateTime date,
          {int? minutes,
          AccountEntity? account,
          ScheduledTransactionStatus status =
              ScheduledTransactionStatus.scheduled}) =>
      ScheduledTransactionEntity(
          id: id,
          seriesId: 'series',
          amountMinor: 100,
          date: date,
          status: status,
          account: account,
          recurringTransactionSeries: RecurringTransactionSeriesEntity(
              id: 'series',
              description: 'Rent',
              amountMinor: 100,
              type: RecurringSeriesKind.expense,
              categoryId: 'c',
              accountId: 'a',
              frequency: 'MONTHLY',
              startDate: now,
              autoPost: false,
              reminderMinutes: minutes,
              mode: RecurringSeriesMode.repeating));

  test('only schedules pending reminders whose trigger is in the future', () {
    final bills = [
      bill('later', now.add(const Duration(hours: 2)), minutes: 30),
      bill('sooner', now.add(const Duration(hours: 1)), minutes: 15),
      bill('past reminder', now.add(const Duration(minutes: 10)), minutes: 15),
      bill('posted', now.add(const Duration(hours: 1)),
          minutes: 5, status: ScheduledTransactionStatus.posted),
      bill('skipped', now.add(const Duration(hours: 1)),
          minutes: 5, status: ScheduledTransactionStatus.skipped),
      bill('off', now.add(const Duration(hours: 1))),
    ];
    expect(upcomingReminders(bills, now).map((bill) => bill.id),
        ['sooner', 'later']);
  });

  test('keeps only the closest 60 reminders for the platform queue', () {
    final bills = List.generate(
        75, (i) => bill('$i', now.add(Duration(minutes: 100 + i)), minutes: 5));
    final result = upcomingReminders(bills.reversed, now);
    expect(result, hasLength(60));
    expect(result.first.id, '0');
    expect(result.last.id, '59');
  });

  test('archived account reminders are paused', () {
    const archived = AccountEntity(
      id: 'a',
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: 'USD',
      balanceMinor: 0,
      archived: true,
      lastUpdatedEventId: 1,
    );
    expect(
        upcomingReminders([
          bill('archived', now.add(const Duration(hours: 1)),
              minutes: 5, account: archived),
        ], now),
        isEmpty);
  });
}
