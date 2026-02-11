# Ledger Domain API Contract

**Feature**: `003-event-sourced-ledger`

This contract defines the strict separation between the `Domain Layer` (Command Handler) and the `Presentation Layer` (UI/ViewModels).

## 1. Commands (Write Side)

The UI invokes these methods on `LedgerService`.

```dart
abstract class LedgerService {
  /// Posts a new transaction (Income/Expense).
  /// Emits: TransactionPosted
  Future<void> postTransaction({
    required double amount, // Converted to int internally
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? note,
    List<String> tags = const [],
  });

  /// Posts a transfer between two accounts.
  /// Emits: TransactionPosted (with 2 legs)
  Future<void> postTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  });

  /// Reverses an existing transaction.
  /// Emits: TransactionReversed
  /// effectively "Deleting" or "Voiding" it.
  Future<void> reverseTransaction({
    required String transactionId,
    required String reason,
  });

  /// Edits a transaction by reversing the old one and posting a new one.
  /// Emits: TransactionReversed(old) + TransactionPosted(new)
  Future<void> correctTransaction({
    required String oldTransactionId,
    required TransactionDetails newDetails,
    required String reason,
  });

  /// Adjusts account balance to a target value.
  /// Emits: BalanceAdjustmentApplied
  Future<void> reconcileBalance({
    required String accountId,
    required double targetBalance,
    required DateTime date,
  });
}
```

## 2. Queries (Read Side)

The UI consumes these Streams/Futures via Riverpod Providers.

```dart
abstract class LedgerRepository {
  /// Stream of the current balance for an account.
  /// Updates immediately after an event is processed.
  Stream<AccountView> watchAccount(String accountId);

  /// Stream of transactions for a date range (e.g., current month).
  Stream<List<TransactionView>> watchTransactions({
    required DateTime start,
    required DateTime end,
    String? accountId,
  });

  /// Get the full audit log for a transaction (Original + Reversals).
  Future<List<LedgerEvent>> getTransactionHistory(String transactionId);
}
```

## 3. Data Transfer Objects (DTOs)

```dart
class TransactionView {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final bool isVoided;
  // ...
}

class AccountView {
  final String id;
  final double currentBalance;
  // ...
}
```
