import 'package:feather_ledger/core/domain/entities/account.dart';

/// Read model for the event-sourced `accounts_view` projection. Writes go
/// exclusively through account commands → the projector (spec 003,
/// US3/T027).
abstract class AccountRepository {
  /// Watches all accounts (including archived — balance totals and history
  /// include them).
  Stream<List<AccountEntity>> watchAccounts();

  /// Gets a single account by its [id], or null if not found.
  Future<AccountEntity?> getAccount(String id);
}
