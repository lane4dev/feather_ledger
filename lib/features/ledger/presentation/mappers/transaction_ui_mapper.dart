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
    final category = e.category;
    final account = e.account;

    final displayAmount = formatMinor(amount);
    // Transfers carry no sign — the two legs net to zero (spec US5).
    final displaySign = e.type == TransactionKind.transfer
        ? ''
        : (e.type == TransactionKind.income ? '+' : '-');

    return TransactionTileUiModel(
      id: id,
      amount: amount,
      type: type,
      date: date,
      note: note,
      category: category,
      account: account,
      toAccount: e.toAccount,
      displayAmount: displayAmount,
      displaySign: displaySign,
    );
  }
}
