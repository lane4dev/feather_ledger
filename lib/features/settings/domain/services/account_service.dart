import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/record_transaction_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/create_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/rename_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/archive_account_command.dart';
import 'package:feather_ledger/features/settings/domain/queries/watch_all_accounts_query.dart';
import 'package:feather_ledger/features/settings/domain/queries/get_account_by_id_query.dart';

part 'account_service.g.dart';

class AccountService {
  final CreateAccountCommand _createAccountCommand;
  final RenameAccountCommand _renameAccountCommand;
  final ArchiveAccountCommand _archiveAccountCommand;
  final WatchAllAccountsQuery _watchAllAccountsQuery;
  final GetAccountByIdQuery _getAccountByIdQuery;
  final RecordTransactionCommand _recordTransactionCommand;
  final CategoryRepository _categoryRepository;

  AccountService(
    this._createAccountCommand,
    this._renameAccountCommand,
    this._archiveAccountCommand,
    this._watchAllAccountsQuery,
    this._getAccountByIdQuery,
    this._recordTransactionCommand,
    this._categoryRepository,
  );

  // Write methods take [commandId] as the idempotency key: retrying the same
  // user action with the same key produces no duplicate events.

  Future<Result<void>> createAccount({
    required String commandId,
    required String name,
    required AccountType type,
    required int initialBalanceMinor,
    required String currencyCode,
  }) {
    return guard(() => _createAccountCommand.execute(
        commandId: commandId,
        name: name,
        type: type,
        initialBalanceMinor: initialBalanceMinor,
        currencyCode: currencyCode));
  }

  Future<Result<void>> renameAccount({
    required String commandId,
    required String accountId,
    required String name,
  }) {
    return guard(() => _renameAccountCommand.execute(
        commandId: commandId, accountId: accountId, name: name));
  }

  Future<Result<void>> archiveAccount({
    required String commandId,
    required String accountId,
  }) {
    return guard(() => _archiveAccountCommand.execute(
        commandId: commandId, accountId: accountId));
  }

  /// Balance adjustment as a normal transaction through the built-in
  /// system adjustment category (spec Command Model: no separate
  /// adjustment command — US4/T036).
  Future<Result<void>> adjustAccountBalance({
    required String commandId,
    required String accountId,
    required int newBalanceMinor,
    required String description,
    required String notes,
  }) {
    return guard(() async {
      final account = await _getAccountByIdQuery.execute(accountId);
      if (account == null) {
        throw CommandRejected(LedgerErrorCode.accountNotFound,
            'Account $accountId not found');
      }
      final diff = newBalanceMinor - account.balanceMinor;
      if (diff == 0) return;

      final systemCode = diff > 0
          ? CategoryConstants.reversalIncomeCode
          : CategoryConstants.reversalExpenseCode;
      final category = await _categoryRepository.getBySystemCode(systemCode);
      if (category == null) {
        throw CommandRejected(LedgerErrorCode.categoryNotFound,
            'System category $systemCode missing');
      }

      await _recordTransactionCommand.execute(
        commandId: commandId,
        amountMinor: diff.abs(),
        kind: diff > 0 ? TransactionKind.income : TransactionKind.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        accountId: accountId,
        note: description,
      );
    });
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
    ref.watch(renameAccountCommandProvider),
    ref.watch(archiveAccountCommandProvider),
    ref.watch(watchAllAccountsQueryProvider),
    ref.watch(getAccountByIdQueryProvider),
    ref.watch(recordTransactionCommandProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
