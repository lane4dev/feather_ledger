# Quickstart: Event-Sourced Ledger

## 1. Setup

Ensure you have the latest dependencies:
```bash
flutter pub get
```

Generate the new Drift code:
```bash
dart run build_runner build -d
```

## 2. Usage (Developer)

### Accessing the Ledger Service
The `LedgerService` is the entry point for all writes.

```dart
final ledgerService = ref.read(ledgerServiceProvider);

// Post an expense
await ledgerService.postTransaction(
  amount: -50.00, 
  accountId: 'checking-123',
  categoryId: 'food-456',
  date: DateTime.now(),
  note: 'Lunch'
);
```

### Watching Data
Use the generated providers to observe the Read Models.

```dart
// Watch account balance
final accountAsync = ref.watch(accountProvider('checking-123'));

// Watch transaction list
final transactionsAsync = ref.watch(monthlyTransactionsProvider(DateTime.now()));
```

## 3. Debugging / Audit

To view the raw Event Log for debugging:

1. Open the App Database Inspector in Android Studio.
2. Query the `ledger_events` table:
   ```sql
   SELECT * FROM ledger_events ORDER BY id DESC;
   ```

To force a projection rebuild (e.g., if development schema changed):
```dart
await ref.read(ledgerRepositoryProvider).rebuildProjections();
```
