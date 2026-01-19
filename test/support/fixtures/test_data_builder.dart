import 'package:feather_ledger/core/database/app_database.dart';
import 'package:feather_ledger/core/database/daos/transaction_dao.dart';
import 'package:feather_ledger/core/database/tables.dart';

/// Test helpers for creating database entities
class TestDataBuilder {
  static Transaction createTransaction({
    int id = 1,
    double amount = 100.0,
    TransactionType type = TransactionType.expense,
    DateTime? date,
    String? note,
    int categoryId = 1,
    int accountId = 1,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id,
      amount: amount,
      type: type,
      date: date ?? DateTime.now(),
      note: note,
      categoryId: categoryId,
      accountId: accountId,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static Category createCategory({
    int id = 1,
    String name = 'Test Category',
    String iconKey = 'test_icon',
    int colorInt = 0xFF000000,
    TransactionType type = TransactionType.expense,
    bool isDefault = false,
  }) {
    return Category(
      id: id,
      name: name,
      iconKey: iconKey,
      colorInt: colorInt,
      type: type,
      isDefault: isDefault,
    );
  }

  static Account createAccount({
    int id = 1,
    String name = 'Test Account',
    AccountType type = AccountType.cash,
    double initialBalance = 0.0,
  }) {
    return Account(
      id: id,
      name: name,
      type: type,
      initialBalance: initialBalance,
    );
  }

  static TransactionWithDetails createTransactionWithDetails({
    Transaction? transaction,
    Category? category,
    Account? account,
  }) {
    return TransactionWithDetails(
      transaction ?? createTransaction(),
      category ?? createCategory(),
      account ?? createAccount(),
    );
  }
}
