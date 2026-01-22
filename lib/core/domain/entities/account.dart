import 'package:feather_ledger/core/domain/entities/enums.dart';

class AccountEntity {
  final int id;
  final String name;
  final AccountType type;
  final double initialBalance;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
  });
}
