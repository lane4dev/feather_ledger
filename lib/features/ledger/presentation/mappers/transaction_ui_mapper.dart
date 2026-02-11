import 'package:feather_ledger/core/domain/enums.dart';

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

    final displayAmount = (e.amount.abs() / 100.0)
        .toStringAsFixed(2); // Assuming amount is in cents
    final displaySign = e.type == TransactionType.income ? '+' : '-';

    return TransactionTileUiModel(
      id: id,
      amount: amount,
      type: type,
      date: date,
      note: note,
      category: category,
      account: account,
      displayAmount: displayAmount,
      displaySign: displaySign,
    );
  }
}
