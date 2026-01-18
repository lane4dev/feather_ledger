import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';
import 'package:flutter/material.dart' show Colors, Icons;

Future<void> seedDatabase(AppDatabase db) async {
  // Check if categories exist
  final categories = await db.transactionDao.getAllCategories();
  if (categories.isEmpty) {
    print('Seeding Categories...');
    await db.batch((batch) {
      batch.insertAll(db.categories, [
        CategoriesCompanion.insert(name: 'Food', iconKey: '${Icons.restaurant.codePoint}', colorInt: Colors.orange.value, type: TransactionType.expense),
        CategoriesCompanion.insert(name: 'Transport', iconKey: '${Icons.directions_bus.codePoint}', colorInt: Colors.blue.value, type: TransactionType.expense),
        CategoriesCompanion.insert(name: 'Shopping', iconKey: '${Icons.shopping_bag.codePoint}', colorInt: Colors.pink.value, type: TransactionType.expense),
        CategoriesCompanion.insert(name: 'Salary', iconKey: '${Icons.attach_money.codePoint}', colorInt: Colors.green.value, type: TransactionType.income),
        CategoriesCompanion.insert(name: 'Bonus', iconKey: '${Icons.card_giftcard.codePoint}', colorInt: Colors.purple.value, type: TransactionType.income),
      ]);
    });
  }

  // Check if accounts exist
  final accounts = await db.transactionDao.getAllAccounts();
  if (accounts.isEmpty) {
    print('Seeding Accounts...');
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
