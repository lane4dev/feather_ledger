import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart'; // Import AppLocalizations

import '../../../app/theme/category_tokens.dart';
import '../../domain/entities/enums.dart';

import 'app_database.dart';
// import 'tables.dart';

Future<void> seedDatabase(AppDatabase db, AppLocalizations l10n) async {
  // Check if categories exist
  final categories = await db.transactionDao.getAllCategories();
  if (categories.isEmpty) {
    debugPrint('Seeding Categories...');
    const defaultColors = CategoryTokens.defaultColors;
    final defaultIcons = CategoryTokens.defaultIcons;

    await db.batch((batch) {
      batch.insertAll(db.categories, [
        CategoriesCompanion.insert(
            name: l10n.categoryFood, // Use localized string
            iconKey: '${defaultIcons[0]}',
            colorInt: defaultColors[0].toARGB32(),
            type: TransactionType.expense),
        CategoriesCompanion.insert(
            name: l10n.categoryTransport, // Use localized string
            iconKey: '${defaultIcons[2]}',
            colorInt: defaultColors[2].toARGB32(),
            type: TransactionType.expense),
        CategoriesCompanion.insert(
            name: l10n.categoryShopping, // Use localized string
            iconKey: '${defaultIcons[1]}',
            colorInt: defaultColors[1].toARGB32(),
            type: TransactionType.expense),
        CategoriesCompanion.insert(
            name: l10n.categorySalary, // Use localized string
            iconKey: '${defaultIcons[7]}',
            colorInt: defaultColors[8].toARGB32(),
            type: TransactionType.income),
        CategoriesCompanion.insert(
            name: l10n.categoryBonus, // Use localized string
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
          name: l10n.accountCash, // Use localized string
          type: AccountType.cash,
          initialBalance: const Value(0.0),
        ));
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: l10n.accountBankCard, // Use localized string
          type: AccountType.bank,
          initialBalance: const Value(1000.0), // Start with some money
        ));
  }
}