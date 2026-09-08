import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/database/daos/transaction_dao.dart';

/// Test helpers for creating database entities
class TestDataBuilder {
  static TransactionViewRow createTransaction({
    String transactionId = 'txn_1',
    DateTime? occurredAt,
    TransactionKind kind = TransactionKind.expense,
    String description = 'Test Transaction',
    bool isReversed = false,
    String categoryName = 'Test Category',
    String categoryIcon = 'test_icon',
    String categoryColorInt = 'ff000000',
    int originalEventId = 1,
    int projectionVersion = 1,
  }) {
    return TransactionViewRow(
      transactionId: transactionId,
      occurredAt: occurredAt ?? DateTime.now(),
      kind: kind,
      description: description,
      isReversed: isReversed,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColorInt: categoryColorInt,
      originalEventId: originalEventId,
      projectionVersion: projectionVersion,
    );
  }

  static TransactionPostingRow createPosting({
    String id = 'posting_1',
    String transactionId = 'txn_1',
    String accountId = 'acc_1',
    PostingDirection direction = PostingDirection.debit,
    int amountMinor = 10000,
    String currencyCode = 'USD',
    String? categoryId = 'cat_1',
    String? memo,
  }) {
    return TransactionPostingRow(
      id: id,
      transactionId: transactionId,
      accountId: accountId,
      direction: direction,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      categoryId: categoryId,
      memo: memo,
    );
  }

  static CategoryViewRow createCategory({
    String id = 'cat_1',
    String name = 'Test Category',
    String iconKey = 'test_icon',
    int colorInt = 0xFF000000,
    CategoryType type = CategoryType.expense,
    bool archived = false,
    String? systemCode,
    int lastUpdatedEventId = 1,
    int projectionVersion = 1,
  }) {
    return CategoryViewRow(
      id: id,
      name: name,
      iconKey: iconKey,
      colorInt: colorInt,
      type: type,
      archived: archived,
      systemCode: systemCode,
      lastUpdatedEventId: lastUpdatedEventId,
      projectionVersion: projectionVersion,
    );
  }

  static AccountViewRow createAccount({
    String id = 'acc_1',
    String name = 'Test Account',
    AccountType type = AccountType.cash,
    String currencyCode = 'USD',
    int balanceMinor = 0,
    bool archived = false,
    int lastUpdatedEventId = 1,
    int projectionVersion = 1,
  }) {
    return AccountViewRow(
      id: id,
      name: name,
      type: type,
      currencyCode: currencyCode,
      balanceMinor: balanceMinor,
      archived: archived,
      lastUpdatedEventId: lastUpdatedEventId,
      projectionVersion: projectionVersion,
    );
  }

  static TransactionWithDetails createTransactionWithDetails({
    TransactionViewRow? transaction,
    TransactionPostingRow? posting,
    AccountViewRow? account,
  }) {
    return TransactionWithDetails(
      transaction ?? createTransaction(),
      posting ?? createPosting(),
      account ?? createAccount(),
    );
  }
}
