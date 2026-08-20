import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import 'package:feather_ledger/features/ledger/domain/commands/record_transaction_command.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/settings/domain/commands/create_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/rename_account_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/account_lifecycle_command.dart';
import 'package:feather_ledger/features/settings/domain/commands/set_account_totals_inclusion_command.dart';
import 'package:feather_ledger/features/settings/domain/queries/watch_all_accounts_query.dart';
import 'package:feather_ledger/features/settings/domain/queries/get_account_by_id_query.dart';

part 'account_service.g.dart';

class AccountService {
  final CreateAccountCommand _createAccountCommand;
  final RenameAccountCommand _renameAccountCommand;
  final AccountLifecycleCommand _accountLifecycleCommand;
  final WatchAllAccountsQuery _watchAllAccountsQuery;
  final GetAccountByIdQuery _getAccountByIdQuery;
  final RecordTransactionCommand _recordTransactionCommand;
  final SetAccountTotalsInclusionCommand _setTotalsInclusionCommand;
  final RecurringService _recurringService;

  AccountService(
    this._createAccountCommand,
    this._renameAccountCommand,
    this._accountLifecycleCommand,
    this._watchAllAccountsQuery,
    this._getAccountByIdQuery,
    this._recordTransactionCommand,
    this._setTotalsInclusionCommand,
    this._recurringService,
  );

  // Write methods take [commandId] as the idempotency key: retrying the same
  // user action with the same key produces no duplicate events.

  /// Creates an account and, when non-zero, records its starting balance as a
  /// balance adjustment. It remains visible and auditable, but is neither a
  /// current-period income/expense nor a hidden system category.
  ///
  /// [includeInTotals] is [SetAccountTotalsInclusionCommand] reached from the
  /// create form: an account is born counting, so opting out at birth is a
  /// second event rather than a field on `AccountCreated` — the same pairing
  /// as the starting balance above, and it keeps a published payload from
  /// having to grow a version.
  Future<Result<void>> createAccount({
    required String commandId,
    required String name,
    required AccountType type,
    required int initialBalanceMinor,
    required String currencyCode,
    String? initialBalanceNote,
    bool includeInTotals = true,
  }) {
    return guard(() async {
      final accountId = await _createAccountCommand.execute(
          commandId: commandId,
          name: name,
          type: type,
          currencyCode: currencyCode);

      if (!includeInTotals) {
        await _setTotalsInclusionCommand.execute(
          commandId: '$commandId-inclusion',
          accountId: accountId,
          includeInTotals: false,
        );
      }

      if (initialBalanceMinor == 0) return;

      // Its own commandId, derived rather than minted: the pair is one user
      // action, so a retry is deduplicated as a pair instead of leaving an
      // account with no record of the money it was opened with.
      await _recordTransactionCommand.executeBalanceAdjustment(
        commandId: '$commandId-opening',
        signedAmountMinor: initialBalanceMinor,
        occurredAt: DateTime.now(),
        accountId: accountId,
        note: initialBalanceNote,
      );
    });
  }

  /// Includes the account in, or takes it out of, the **ledger totals**
  /// (CONTEXT.md): the header's balance and the month's income and expense,
  /// each day's subtotals, and the reports. The account itself, its balance
  /// and its transactions are untouched — this moves which sums it appears
  /// in, not what any of them says.
  Future<Result<void>> setTotalsInclusion({
    required String commandId,
    required String accountId,
    required bool includeInTotals,
  }) {
    return guard(() => _setTotalsInclusionCommand.execute(
          commandId: commandId,
          accountId: accountId,
          includeInTotals: includeInTotals,
        ));
  }

  Future<Result<void>> renameAccount({
    required String commandId,
    required String accountId,
    required String name,
  }) {
    return guard(() => _renameAccountCommand.execute(
        commandId: commandId, accountId: accountId, name: name));
  }

  Future<AccountUsage> accountUsage(String id) =>
      _accountLifecycleCommand.usage(id);

  Future<Result<void>> restoreAccount(
      {required String commandId, required String accountId}) async {
    final result = await guard(() => _accountLifecycleCommand.execute(
        id: accountId, commandId: commandId, action: 'restore'));
    if (result is Success<void>) {
      await guard(() => _recurringService.materialize());
      await guard(
          () => _recurringService.catchUpAutoPosted(accountId: accountId));
    }
    return result;
  }

  Future<Result<void>> deleteAccount(
          {required String commandId, required String accountId}) =>
      guard(() => _accountLifecycleCommand.execute(
          id: accountId, commandId: commandId, action: 'delete'));

  Future<Result<void>> deleteAccountWithTransactions(
          {required String commandId, required String accountId}) =>
      guard(() => _accountLifecycleCommand.execute(
          id: accountId, commandId: commandId, action: 'deleteAll'));

  Future<Result<void>> moveAccountTransactions({
    required String commandId,
    required String accountId,
    required String targetAccountId,
  }) =>
      guard(() => _accountLifecycleCommand.execute(
          id: accountId,
          commandId: commandId,
          action: 'move',
          targetAccountId: targetAccountId));

  Future<Result<void>> archiveAccount({
    required String commandId,
    required String accountId,
  }) {
    return guard(() => _accountLifecycleCommand.execute(
        commandId: commandId, id: accountId, action: 'archive'));
  }

  /// Reconciles the account to [newBalanceMinor] by recording the signed
  /// difference as a category-free balance adjustment. It never changes a
  /// projection balance directly.
  Future<Result<void>> adjustAccountBalance({
    required String commandId,
    required String accountId,
    required int newBalanceMinor,
    required String notes,
  }) {
    return guard(() async {
      final account = await _getAccountByIdQuery.execute(accountId);
      if (account == null) {
        throw CommandRejected(
            LedgerErrorCode.accountNotFound, 'Account $accountId not found');
      }
      final diff = newBalanceMinor - account.balanceMinor;
      if (diff == 0) return;

      await _recordTransactionCommand.executeBalanceAdjustment(
        commandId: commandId,
        signedAmountMinor: diff,
        occurredAt: DateTime.now(),
        accountId: accountId,
        note: notes,
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
    ref.watch(accountLifecycleCommandProvider),
    ref.watch(watchAllAccountsQueryProvider),
    ref.watch(getAccountByIdQueryProvider),
    ref.watch(recordTransactionCommandProvider),
    ref.watch(setAccountTotalsInclusionCommandProvider),
    ref.watch(recurringServiceProvider),
  );
}
