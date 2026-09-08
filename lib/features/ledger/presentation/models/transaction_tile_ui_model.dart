import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';

class TransactionTileUiModel {
  final String id;
  final int amount;
  final TransactionKind type;
  final DateTime date;
  final String? note;

  final CategoryEntity category;
  final AccountEntity account;

  /// Credit-side account — set only for kind=transfer (spec 003, US5/T042).
  final AccountEntity? toAccount;

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
    this.toAccount,
    required this.displayAmount,
    required this.displaySign,
  });
}
