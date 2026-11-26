import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

export 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart'
    show kPlannedOccurrenceKey, scheduledOccurrenceKey;

enum ScheduledTransactionStatus {
  scheduled,
  posted,
  skipped,
  failed,
}

/// How far an edit reaches into a recurring series.
enum RecurringScope {
  /// Only this single occurrence (stored as sparse override columns).
  thisOnly,

  /// Update the rule template and unposted future occurrences.
  updateRule,
}

/// The `scheduled_transactions_view.status` column stores the enum *name*
/// (it is a plain TEXT column, not an intEnum). Both directions live here so
/// a writer and a reader cannot drift apart — decoding used to have no
/// `orElse` in one repository and one in another (spec 004, FR-013).
extension ScheduledTransactionStatusStorage on ScheduledTransactionStatus {
  String toStorage() => name;
}

/// Decodes a stored status. An unrecognised string degrades to [scheduled]
/// rather than throwing: a bad row must not take down the screen that lists
/// it.
ScheduledTransactionStatus decodeScheduledStatus(String raw) =>
    ScheduledTransactionStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => ScheduledTransactionStatus.scheduled,
    );

class TransactionEntity {
  final String id;
  final int amount;
  final TransactionKind type;
  final DateTime date;
  final String? note;
  final List<TransactionAttachment> attachments;

  /// Present only for ordinary income/expense transactions. Balance purposes
  /// and transfers intentionally have no category.
  final CategoryEntity? category;

  /// Debit-side account (the "from" side for transfers).
  final AccountEntity account;

  /// Credit-side account — set only for kind=transfer (spec 003, US5/T042).
  final AccountEntity? toAccount;
  final bool isReversed;
  final int eventId;

  /// The scheduled-bill instance this transaction was posted from (spec 006,
  /// US47). Null for ad-hoc transactions; survives corrections so the latest
  /// correction still points at the same source bill.
  final String? sourceScheduledBillId;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.attachments = const [],
    this.category,
    required this.account,
    this.toAccount,
    this.isReversed = false,
    required this.eventId,
    this.sourceScheduledBillId,
  });

  TransactionEntity copyWith({
    String? id,
    int? amount,
    TransactionKind? type,
    DateTime? date,
    String? note,
    List<TransactionAttachment>? attachments,
    CategoryEntity? category,
    AccountEntity? account,
    AccountEntity? toAccount,
    bool? isReversed,
    int? eventId,
    String? sourceScheduledBillId,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      attachments: attachments ?? this.attachments,
      category: category ?? this.category,
      account: account ?? this.account,
      toAccount: toAccount ?? this.toAccount,
      isReversed: isReversed ?? this.isReversed,
      eventId: eventId ?? this.eventId,
      sourceScheduledBillId:
          sourceScheduledBillId ?? this.sourceScheduledBillId,
    );
  }
}

class ScheduledTransactionEntity {
  final String id;
  final String seriesId;
  final String occurrenceKey;
  final DateTime scheduledDate;
  final int? amountOverrideMinor;
  final DateTime? dateOverride;
  final String? memoOverride;
  final ScheduledTransactionStatus status;
  final bool manualOnly;
  final String? transactionId;
  final RecurringTransactionSeriesEntity? recurringTransactionSeries;

  /// Resolved from the series so a pending bill can be rendered as a row in
  /// the ledger list — the same shape a posted transaction arrives in.
  /// Null when the series' category or account has since been removed, which
  /// the list treats as "render without that detail" rather than failing.
  final TransactionKind? kind;
  final CategoryEntity? category;
  final AccountEntity? account;

  DateTime get effectiveDate => dateOverride ?? scheduledDate;
  int get effectiveAmountMinor =>
      amountOverrideMinor ?? recurringTransactionSeries?.amountMinor ?? 0;
  String get effectiveMemo =>
      memoOverride ?? recurringTransactionSeries?.description ?? '';

  /// Convenience aliases matching the effective values.
  DateTime get date => effectiveDate;
  int get amountMinor => effectiveAmountMinor;

  const ScheduledTransactionEntity({
    required this.id,
    required this.seriesId,
    required this.occurrenceKey,
    required this.scheduledDate,
    this.amountOverrideMinor,
    this.dateOverride,
    this.memoOverride,
    this.status = ScheduledTransactionStatus.scheduled,
    this.manualOnly = false,
    this.transactionId,
    this.recurringTransactionSeries,
    this.kind,
    this.category,
    this.account,
  });

  ScheduledTransactionEntity copyWith({
    String? id,
    String? seriesId,
    String? occurrenceKey,
    DateTime? scheduledDate,
    int? amountOverrideMinor,
    DateTime? dateOverride,
    String? memoOverride,
    ScheduledTransactionStatus? status,
    bool? manualOnly,
    String? transactionId,
    RecurringTransactionSeriesEntity? recurringTransactionSeries,
    TransactionKind? kind,
    CategoryEntity? category,
    AccountEntity? account,
  }) {
    return ScheduledTransactionEntity(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      amountOverrideMinor: amountOverrideMinor ?? this.amountOverrideMinor,
      dateOverride: dateOverride ?? this.dateOverride,
      memoOverride: memoOverride ?? this.memoOverride,
      status: status ?? this.status,
      manualOnly: manualOnly ?? this.manualOnly,
      transactionId: transactionId ?? this.transactionId,
      recurringTransactionSeries:
          recurringTransactionSeries ?? this.recurringTransactionSeries,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      account: account ?? this.account,
    );
  }
}

class RecurringTransactionSeriesEntity {
  final String id;
  final String description;
  final int amountMinor;

  /// Never `transfer`: a series has a single account (ADR-0002).
  final RecurringSeriesKind type;
  final String categoryId;
  final String accountId;
  final String frequency; // e.g., 'monthly', 'weekly'
  final String? rrule;
  final DateTime startDate;
  final DateTime? endDate;
  final int? interval; // e.g., every '2' months
  final int? limit; // e.g., limit to '5' occurrences

  /// Whether due instances post themselves at launch.
  final bool autoPost;
  final int? reminderMinutes;

  /// The creation mode (计划 / 重复). Immutable after creation.
  final RecurringSeriesMode mode;
  final bool isActive;
  final DateTime? materializeFrom;
  final int completedCountOffset;

  DateTime get effectiveMaterializeFrom => materializeFrom ?? startDate;

  const RecurringTransactionSeriesEntity({
    required this.id,
    required this.description,
    required this.amountMinor,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    this.rrule,
    required this.startDate,
    this.endDate,
    this.interval,
    this.limit,
    required this.autoPost,
    this.reminderMinutes,
    required this.mode,
    this.isActive = true,
    this.materializeFrom,
    this.completedCountOffset = 0,
  });
}
