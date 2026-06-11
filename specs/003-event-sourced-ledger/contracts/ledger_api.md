# Ledger Domain API Contract

> ⚠️ **迁移前文档（过期标记，T001）**：本 API 契约描述迁移前设计，已被已确认规格 [spec.md](spec.md)（2026-09-06 同步）取代，**不可作为实现依据**。过期内容：
> - **double 金额参数与 DTO**（`TransactionView.amount`、`AccountView.currentBalance` 等）：终稿金额一律 int minor units / `Money` VO，禁止 double/float。
> - **旧命令集**：`postTransaction` / `postTransfer` / `reverseTransaction` / `correctTransaction` / `reconcileBalance`。终稿命令集为 `CreateAccount` / `RenameAccount` / `ArchiveAccount` / `CreateCategory` / `RenameCategory` / `ArchiveCategory` / `RecordTransaction` / `ReverseTransaction` / `CorrectTransaction` / `ConvertScheduledToPosted`，全部携带 commandId（幂等）并在同一数据库事务内 append 事件 + 同步投影。
> - **`BalanceAdjustmentApplied` 事件**（已否决）：账户余额调整改经 `RecordTransaction` 挂内置系统调整分类。
> - **`Future<void>` 裸异常返回**：终稿命令返回 `Result<T>`，失败携带用户可读错误码，ViewModel 不捕获裸异常。
>
> 终稿命令契约见 spec.md「Command Model / 命令模型」。

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
