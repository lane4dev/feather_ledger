import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';

class TransactionUiMapper {
  const TransactionUiMapper();

  TransactionTileUiModel toTile(TransactionEntity e) {
    final id = e.id;
    final amount = e.amount.abs();
    final type = e.type;
    final date = e.date;
    final note = e.note;
    final attachments = e.attachments;
    final category = e.category;
    final account = e.account;

    final displayAmount = formatMinor(amount);
    // Transfers carry no sign — the two legs net to zero. Balance purposes
    // retain their real signed impact without becoming income/expense.
    final displaySign = switch (e.type) {
      TransactionKind.transfer => '',
      TransactionKind.income => '+',
      TransactionKind.expense => '-',
      TransactionKind.openingBalance ||
      TransactionKind.balanceAdjustment =>
        e.amount >= 0 ? '+' : '-',
    };

    return TransactionTileUiModel(
      id: id,
      amount: amount,
      type: type,
      date: date,
      note: note,
      attachments: attachments,
      category: category,
      account: account,
      toAccount: e.toAccount,
      displayAmount: displayAmount,
      displaySign: displaySign,
    );
  }

  /// A recurring series' upcoming instance, as a list row.
  ///
  /// The category and account are passed in rather than read off the entity
  /// so the caller has to have resolved them — a pending row that cannot name
  /// its category or account has nothing to show and should be filtered out
  /// before it gets here.
  ///
  /// A series is never a transfer (`RecurringSeriesKind` has no such member),
  /// so the sign is always one of two.
  TransactionTileUiModel toPendingTile(
    ScheduledTransactionEntity e, {
    required CategoryEntity category,
    required AccountEntity account,
  }) {
    final kind = e.kind ?? TransactionKind.expense;
    // Positive, like [toTile]'s: the sign lives in `displaySign`, and the
    // kind is what decides which sign that is. Taken here rather than trusted
    // from the writer — a series amount is positive by convention
    // (`CreateRecurringSeriesCommand` rejects anything else), but the column
    // is a plain int and a row from any other source would otherwise render
    // as "- $-500.00".
    final amount = e.amountMinor.abs();

    return TransactionTileUiModel(
      id: e.id,
      amount: amount,
      type: kind,
      date: e.date,
      // The series' description is what the user named this bill; a pending
      // instance has no note of its own.
      note: e.recurringTransactionSeries?.description,
      category: category,
      account: account,
      displayAmount: formatMinor(amount),
      displaySign: kind == TransactionKind.income ? '+' : '-',
      isPending: true,
      seriesId: e.seriesId,
    );
  }
}
