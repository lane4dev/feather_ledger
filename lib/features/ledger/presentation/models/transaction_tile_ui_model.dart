import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
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

  /// A bill that has not happened yet — a recurring series' upcoming
  /// instance, shown in the month list but not part of the ledger. It is
  /// rendered muted and is acted on by posting or skipping, not by editing.
  ///
  /// [id] is the scheduled instance's id in that case, not a transaction's.
  final bool isPending;

  /// The series a pending bill belongs to, so it can be posted, skipped or
  /// switched off from the row. Null for anything already recorded.
  final String? seriesId;

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
    this.seriesId,
  });
}
