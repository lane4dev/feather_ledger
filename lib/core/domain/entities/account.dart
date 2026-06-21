import 'package:feather_ledger/core/domain/enums.dart';

/// Account projection entity (spec 003, US3): single balance in minor units,
/// creation currency, archived flag and the source GSN cursor.
class AccountEntity {
  final String id;
  final String name;
  final AccountType type;
  final String currencyCode;
  final int balanceMinor;
  final bool archived;
  final int lastUpdatedEventId;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.balanceMinor,
    required this.archived,
    required this.lastUpdatedEventId,
  });

  /// Whether spending [amountMinor] would take this account below zero.
  /// Credit accounts are exempt — a negative balance is their normal state.
  /// The caller warns; it does not block.
  bool wouldOverdraft(int amountMinor) =>
      type != AccountType.credit && balanceMinor - amountMinor < 0;
}
