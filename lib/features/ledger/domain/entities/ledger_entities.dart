import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

enum ScheduledTransactionStatus {
  scheduled,
  posted,
  skipped,
  failed,
}

class TransactionEntity {
  final String id;
  final int amount;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final CategoryEntity category;
  final AccountEntity account;
  final bool isReversed;
  final int eventId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.category,
    required this.account,
    this.isReversed = false,
    required this.eventId,
  });

  TransactionEntity copyWith({
    String? id,
    int? amount,
    TransactionType? type,
    DateTime? date,
    String? note,
    CategoryEntity? category,
    AccountEntity? account,
    bool? isReversed,
    int? eventId,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      category: category ?? this.category,
      account: account ?? this.account,
      isReversed: isReversed ?? this.isReversed,
      eventId: eventId ?? this.eventId,
    );
  }
}

class ScheduledTransactionEntity {
  final String id;
  final String seriesId;
  final double amount;
  final DateTime date;
  final ScheduledTransactionStatus status;
  final String? transactionId;
  final RecurringTransactionSeriesEntity? recurringTransactionSeries;

  const ScheduledTransactionEntity({
    required this.id,
    required this.seriesId,
    required this.amount,
    required this.date,
    this.status = ScheduledTransactionStatus.scheduled,
    this.transactionId,
    this.recurringTransactionSeries,
  });

  ScheduledTransactionEntity copyWith({
    String? id,
    String? seriesId,
    double? amount,
    DateTime? date,
    ScheduledTransactionStatus? status,
    String? transactionId,
    RecurringTransactionSeriesEntity? recurringTransactionSeries,
  }) {
    return ScheduledTransactionEntity(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      recurringTransactionSeries:
          recurringTransactionSeries ?? this.recurringTransactionSeries,
    );
  }
}

class RecurringTransactionSeriesEntity {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String frequency; // e.g., 'monthly', 'weekly'
  final DateTime startDate;
  final DateTime? endDate;
  final int? interval; // e.g., every '2' months
  final int? limit; // e.g., limit to '5' occurrences

  const RecurringTransactionSeriesEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.interval,
    this.limit,
  });
}
