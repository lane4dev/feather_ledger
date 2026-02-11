import 'package:feather_ledger/core/domain/entities/account.dart';

abstract class AccountRepository {
  /// Watches all accounts as a stream.
  /// Returns a stream of a list of [AccountEntity].
  Stream<List<AccountEntity>> watchAccounts();

  /// Gets a single account by its [id].
  /// Returns an [AccountEntity] or null if not found.
  Future<AccountEntity?> getAccount(String id);

  /// Adds a new account with the given parameters.
  /// Returns a [Future] that completes when the operation is done.
  Future<void> addAccount(AccountEntity account);

  /// Updates an existing account identified by [id] with the given parameters.
  /// Returns a [Future] that completes when the operation is done.
  Future<void> updateAccount(AccountEntity account);

  /// Saves or updates an account projection in the read model.
  // Future<void> saveAccountProjection(AccountsViewCompanion entry);

  /// Deletes an account projection from the read model.
  Future<void> deleteAccountProjection(String id);
}
