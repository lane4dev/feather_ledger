import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/constants/category_constants.dart';

import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/adjust_account_balance_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/create_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/update_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/delete_account_command.dart';
import 'package:feather_ledger/features/settings/domain/queries/watch_all_accounts_query.dart';
import 'package:feather_ledger/features/settings/domain/queries/get_account_by_id_query.dart';

part 'account_service.g.dart';

class AccountService {
  final CreateAccountCommand _createAccountCommand;
  final UpdateAccountCommand _updateAccountCommand;
  final DeleteAccountCommand _deleteAccountCommand;
  final WatchAllAccountsQuery _watchAllAccountsQuery;
  final GetAccountByIdQuery _getAccountByIdQuery;
  final AdjustAccountBalanceCommand _adjustAccountBalanceCommand;
  final CategoryRepository _categoryRepository;

  AccountService(
    this._createAccountCommand,
    this._updateAccountCommand,
    this._deleteAccountCommand,
    this._watchAllAccountsQuery,
    this._getAccountByIdQuery,
    this._adjustAccountBalanceCommand,
    this._categoryRepository,
  );

  Future<void> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    return _createAccountCommand.execute(
        name: name, type: type, initialBalance: initialBalance);
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    double? newBalance,
    String? balanceAdjustmentDescription,
    String? balanceAdjustmentNotes,
  }) async {
    await _updateAccountCommand.execute(accountId: id, name: name, type: type);

    if (newBalance != null) {
      final account = await _getAccountByIdQuery.execute(id);
      if (account != null) {
        final currentBalance = account.postedBalance / 100.0;
        final diff = newBalance - currentBalance;
        if (diff.abs() > 0.001) {
          final systemCode = diff > 0
              ? CategoryConstants.reversalIncomeCode
              : CategoryConstants.reversalExpenseCode;

          final category =
              await _categoryRepository.getBySystemCode(systemCode);

          if (category != null) {
            assert(
              balanceAdjustmentDescription != null &&
                  balanceAdjustmentNotes != null,
              'Balance adjustment text must be provided when updating balance.',
            );
            await _adjustAccountBalanceCommand.execute(
              accountId: id,
              adjustmentAmount: diff,
              date: DateTime.now(),
              categoryId: category.id,
              description: balanceAdjustmentDescription ?? '',
              notes: balanceAdjustmentNotes ?? '',
            );
          }
        }
      }
    }
  }

  Future<void> deleteAccount(String id) async {
    return _deleteAccountCommand.execute(id);
  }

  Stream<List<AccountEntity>> watchAllAccounts() {
    return _watchAllAccountsQuery.execute();
  }

  Future<AccountEntity?> getAccount(String id) {
    return _getAccountByIdQuery.execute(id);
  }
}

@riverpod
AccountService accountService(Ref ref) {
  return AccountService(
    ref.watch(createAccountCommandProvider),
    ref.watch(updateAccountCommandProvider),
    ref.watch(deleteAccountCommandProvider),
    ref.watch(watchAllAccountsQueryProvider),
    ref.watch(getAccountByIdQueryProvider),
    ref.watch(adjustAccountBalanceCommandProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
