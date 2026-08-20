import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';

/// Selects the nearest future reminders from pending bills.
List<ScheduledTransactionEntity> upcomingReminders(
    Iterable<ScheduledTransactionEntity> bills, DateTime now,
    {int limit = 60}) {
  final pending = bills.where((bill) {
    final minutes = bill.recurringTransactionSeries?.reminderMinutes;
    return bill.status == ScheduledTransactionStatus.scheduled &&
        bill.account?.archived != true &&
        minutes != null &&
        minutes > 0 &&
        bill.date.subtract(Duration(minutes: minutes)).isAfter(now);
  }).toList()
    ..sort((a, b) {
      final aTime = a.date.subtract(
          Duration(minutes: a.recurringTransactionSeries!.reminderMinutes!));
      final bTime = b.date.subtract(
          Duration(minutes: b.recurringTransactionSeries!.reminderMinutes!));
      final compared = aTime.compareTo(bTime);
      return compared == 0 ? a.id.compareTo(b.id) : compared;
    });
  return pending.take(limit).toList();
}
