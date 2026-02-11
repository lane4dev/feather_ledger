import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

class TransactionTileUiModel {
  final String id;
  final int amount;
  final TransactionType type;
  final DateTime date;
  final String? note;

  final CategoryEntity category;
  final AccountEntity account;

  final String displayAmount;
  final String displaySign;

  const TransactionTileUiModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
    required this.category,
    required this.account,
    required this.displayAmount,
    required this.displaySign,
  });
}
