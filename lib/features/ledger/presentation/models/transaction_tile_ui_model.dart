import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

class TransactionTileUiModel {
  final String id;
  final int amount;
  final TransactionKind type;
  final DateTime date;
  final String? note;
  final List<TransactionAttachment> attachments;

  final CategoryEntity? category;
  final AccountEntity account;

  /// Credit-side account — set only for kind=transfer (spec 003, US5/T042).
  final AccountEntity? toAccount;

  final String displayAmount;
  final String displaySign;

  /// Compact read-only amount string with sign tightly attached to the
  /// currency symbol (e.g. `-¥10.00`, `+¥10.00`, `¥20.00`).
  String formattedAmount(String currencySymbol) =>
      '$displaySign$currencySymbol$displayAmount';

  /// A bill that has not happened yet — a recurring series' upcoming
  /// instance, shown in the month list but not part of the ledger. It is
  /// rendered muted and is acted on by posting or skipping, not by editing.
  ///
  /// [id] is the scheduled instance's id in that case, not a transaction's.
  final bool isPending;

  /// Scheduled instance status (`scheduled`, `failed`, or `skipped`) when
  /// [isPending] is true; null for posted ledger transactions.
  final ScheduledTransactionStatus? scheduledStatus;

  /// The series a pending bill belongs to, so it can be posted, skipped or
  /// switched off from the row. Null for anything already recorded.
  final String? seriesId;
  final RecurringTransactionSeriesEntity? series;

  /// True for a read-time occurrence that has no physical scheduled row yet.
  /// Tapping it must materialize `(seriesId, occurrenceKey)` before opening
  /// the normal pending-bill sheet.
  final bool isVirtual;

  /// Calendar-day key (`YYYY-MM-DD`) or `'single'` for a virtual occurrence.
  final String? occurrenceKey;

  /// The scheduled bill this recorded transaction was posted from, if any.
  ///
  /// An edit must not change the kind of a posted bill: the row would keep
  /// pointing at a series whose `type` no longer matches the movement.
  final String? sourceScheduledBillId;

  bool get isSkipped => scheduledStatus == ScheduledTransactionStatus.skipped;
  bool get isFailed => scheduledStatus == ScheduledTransactionStatus.failed;
  bool get isScheduledPending =>
      scheduledStatus == ScheduledTransactionStatus.scheduled;

  const TransactionTileUiModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
    this.attachments = const [],
    this.category,
    required this.account,
    this.toAccount,
    required this.displayAmount,
    required this.displaySign,
    this.isPending = false,
    this.scheduledStatus,
    this.seriesId,
    this.series,
    this.isVirtual = false,
    this.occurrenceKey,
    this.sourceScheduledBillId,
  });
}
