import 'package:feather_ledger/core/domain/enums.dart';

class AccountEntity {
  final String id;
  final String name;
  final AccountType type;
  final int postedBalance;
  final int availableBalance;
  final int? lastUpdatedEventId;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.postedBalance,
    required this.availableBalance,
    this.lastUpdatedEventId,
  });
}
