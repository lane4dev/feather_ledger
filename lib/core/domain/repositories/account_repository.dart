import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';

abstract class AccountRepository {
  Stream<List<AccountEntity>> watchAccounts();
  Future<void> addAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
  });
  Future<void> updateAccount({
    required int id,
    required String name,
    required AccountType type,
    required double initialBalance,
  });
  Future<void> deleteAccount(int id);
}
