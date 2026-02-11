import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';

import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';

Future<void> seedDatabase(AppDatabase db, AppLocalizations l10n) async {
  const uuid = Uuid();
  // Check if categories exist
  final categories = await db.transactionsDao.getAllCategories();
  if (categories.isEmpty) {
    debugPrint('Seeding Categories...');
    const defaultColors = CategoryTokens.defaultColors;
    final defaultIcons = CategoryTokens.defaultIcons;

    await db.batch((batch) {
      batch.insertAll(db.categories, [
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryFood,
            iconKey: '${defaultIcons[0]}',
            colorInt: defaultColors[0].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryTransport,
            iconKey: '${defaultIcons[2]}',
            colorInt: defaultColors[5].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryEntertainment,
            iconKey: '${defaultIcons[4]}',
            colorInt: defaultColors[3].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryShopping,
            iconKey: '${defaultIcons[1]}',
            colorInt: defaultColors[1].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryClothing,
            iconKey: '${defaultIcons[12]}',
            colorInt: defaultColors[12].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryHouseholdSupplies,
            iconKey: '${defaultIcons[10]}',
            colorInt: defaultColors[10].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryCommunications,
            iconKey: '${defaultIcons[23]}',
            colorInt: defaultColors[7].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryHealth,
            iconKey: '${defaultIcons[5]}',
            colorInt: defaultColors[15].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryEducation,
            iconKey: '${defaultIcons[6]}',
            colorInt: defaultColors[4].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryGifts,
            iconKey: '${defaultIcons[28]}',
            colorInt: defaultColors[14].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: CategoryConstants.reversalExpenseId,
            name: l10n.categoryReversalExpense,
            iconKey: '${defaultIcons[30]}',
            colorInt: defaultColors[16].toARGB32(),
            type: TransactionType.expense,
            isBuildIn: const Value(true),
            systemCode: const Value(CategoryConstants.reversalExpenseCode)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categorySalary,
            iconKey: '${defaultIcons[7]}',
            colorInt: defaultColors[9].toARGB32(),
            type: TransactionType.income,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryBonus,
            iconKey: '${defaultIcons[29]}',
            colorInt: defaultColors[10].toARGB32(),
            type: TransactionType.income,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryPartTimeJob,
            iconKey: '${defaultIcons[24]}',
            colorInt: defaultColors[8].toARGB32(),
            type: TransactionType.income,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryAllowance,
            iconKey: '${defaultIcons[8]}',
            colorInt: defaultColors[7].toARGB32(),
            type: TransactionType.income,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: uuid.v4(),
            name: l10n.categoryInvestmentReturns,
            iconKey: '${defaultIcons[17]}',
            colorInt: defaultColors[4].toARGB32(),
            type: TransactionType.income,
            isBuildIn: const Value(false)),
        CategoriesCompanion.insert(
            id: CategoryConstants.reversalIncomeId,
            name: l10n.categoryReversalIncome,
            iconKey: '${defaultIcons[31]}',
            colorInt: defaultColors[17].toARGB32(),
            type: TransactionType.income,
            isBuildIn: const Value(true),
            systemCode: const Value(CategoryConstants.reversalIncomeCode)),
      ]);
    });
  }

  // Check if accounts exist
  final accounts = await db.transactionsDao.getAllAccounts();
  if (accounts.isEmpty) {
    debugPrint('Seeding Accounts...');
    await db.accountDao.insertOrReplace(AccountsViewCompanion.insert(
      id: uuid.v4(),
      name: l10n.accountCash,
      type: AccountType.cash,
      postedBalance: 0,
      availableBalance: 0,
      lastUpdatedEventId: 0,
    ));
    await db.accountDao.insertOrReplace(AccountsViewCompanion.insert(
      id: uuid.v4(),
      name: l10n.accountBankCard,
      type: AccountType.bank,
      postedBalance: 100000, // 1000.00
      availableBalance: 100000,
      lastUpdatedEventId: 0,
    ));
  }
}
