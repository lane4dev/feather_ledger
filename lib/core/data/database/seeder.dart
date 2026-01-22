import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../app/theme/category_tokens.dart';
import '../../domain/entities/enums.dart';

import 'app_database.dart';
// import 'tables.dart';

Future<void> seedDatabase(AppDatabase db) async {
  // Check if categories exist
  final categories = await db.transactionDao.getAllCategories();
  if (categories.isEmpty) {
    debugPrint('Seeding Categories...');
    const defaultColors = CategoryTokens.defaultColors;
    final defaultIcons = CategoryTokens.defaultIcons;

    await db.batch((batch) {
      batch.insertAll(db.categories, [
        CategoriesCompanion.insert(
            name: 'Food',
            iconKey: '${defaultIcons[0]}',
            colorInt: defaultColors[0].toARGB32(),
            type: TransactionType.expense),
        CategoriesCompanion.insert(
            name: 'Transport',
            iconKey: '${defaultIcons[2]}',
            colorInt: defaultColors[2].toARGB32(),
            type: TransactionType.expense),
        CategoriesCompanion.insert(
            name: 'Shopping',
            iconKey: '${defaultIcons[1]}',
            colorInt: defaultColors[1].toARGB32(),
            type: TransactionType.expense),
        CategoriesCompanion.insert(
            name: 'Salary',
            iconKey: '${defaultIcons[7]}',
            colorInt: defaultColors[8].toARGB32(),
            type: TransactionType.income),
        CategoriesCompanion.insert(
            name: 'Bonus',
            iconKey: '${defaultIcons[28]}',
            colorInt: defaultColors[2].toARGB32(),
            type: TransactionType.income),
      ]);
    });
  }

  // Check if accounts exist
  final accounts = await db.transactionDao.getAllAccounts();
  if (accounts.isEmpty) {
    debugPrint('Seeding Accounts...');
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Cash',
          type: AccountType.cash,
          initialBalance: const Value(0.0),
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Bank Card',
          type: AccountType.bank,
          initialBalance: const Value(1000.0), // Start with some money
        ));
  }
}
