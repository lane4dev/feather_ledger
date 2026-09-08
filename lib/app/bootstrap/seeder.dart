import 'package:flutter/foundation.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';

import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import 'package:feather_ledger/features/settings/domain/services/account_service.dart';
import 'package:feather_ledger/features/settings/domain/services/category_service.dart';

/// Seeds a fresh install through the standard write path (spec 003,
/// US3/T030): default categories (incl. the two built-in reversal system
/// categories with fixed ids/systemCode) plus Cash and Bank accounts with
/// the Bank opening balance (100000 minor = 1000.00).
///
/// Idempotency condition is an **empty event store** — a store with any
/// event (even with empty projections) is not re-seeded; the data is meant
/// to be replayable, and rebuild restores projections from the event
/// stream.
Future<void> seedDatabase({
  required EventStore eventStore,
  required AccountService accountService,
  required CategoryService categoryService,
  required AppLocalizations l10n,
}) async {
  if (await eventStore.readMaxGlobalSequenceNumber() != null) return;

  debugPrint('Seeding default categories and accounts via the event stream...');
  const defaultColors = CategoryTokens.defaultColors;
  final defaultIcons = CategoryTokens.defaultIcons;

  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-food',
    name: l10n.categoryFood,
    iconKey: '${defaultIcons[0]}',
    colorInt: defaultColors[0].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-transport',
    name: l10n.categoryTransport,
    iconKey: '${defaultIcons[2]}',
    colorInt: defaultColors[5].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-entertainment',
    name: l10n.categoryEntertainment,
    iconKey: '${defaultIcons[4]}',
    colorInt: defaultColors[3].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-shopping',
    name: l10n.categoryShopping,
    iconKey: '${defaultIcons[1]}',
    colorInt: defaultColors[1].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-clothing',
    name: l10n.categoryClothing,
    iconKey: '${defaultIcons[12]}',
    colorInt: defaultColors[12].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-household',
    name: l10n.categoryHouseholdSupplies,
    iconKey: '${defaultIcons[10]}',
    colorInt: defaultColors[10].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-communications',
    name: l10n.categoryCommunications,
    iconKey: '${defaultIcons[23]}',
    colorInt: defaultColors[7].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-health',
    name: l10n.categoryHealth,
    iconKey: '${defaultIcons[5]}',
    colorInt: defaultColors[15].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-education',
    name: l10n.categoryEducation,
    iconKey: '${defaultIcons[6]}',
    colorInt: defaultColors[4].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-gifts',
    name: l10n.categoryGifts,
    iconKey: '${defaultIcons[28]}',
    colorInt: defaultColors[14].toARGB32(),
    type: CategoryType.expense,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-reversal-expense',
    categoryId: CategoryConstants.reversalExpenseId,
    name: l10n.categoryReversalExpense,
    iconKey: '${defaultIcons[30]}',
    colorInt: defaultColors[16].toARGB32(),
    type: CategoryType.expense,
    systemCode: CategoryConstants.reversalExpenseCode,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-salary',
    name: l10n.categorySalary,
    iconKey: '${defaultIcons[7]}',
    colorInt: defaultColors[9].toARGB32(),
    type: CategoryType.income,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-bonus',
    name: l10n.categoryBonus,
    iconKey: '${defaultIcons[29]}',
    colorInt: defaultColors[10].toARGB32(),
    type: CategoryType.income,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-part-time',
    name: l10n.categoryPartTimeJob,
    iconKey: '${defaultIcons[24]}',
    colorInt: defaultColors[8].toARGB32(),
    type: CategoryType.income,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-allowance',
    name: l10n.categoryAllowance,
    iconKey: '${defaultIcons[8]}',
    colorInt: defaultColors[7].toARGB32(),
    type: CategoryType.income,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-investment',
    name: l10n.categoryInvestmentReturns,
    iconKey: '${defaultIcons[17]}',
    colorInt: defaultColors[4].toARGB32(),
    type: CategoryType.income,
  ));
  await _requireSuccess(categoryService.createCategory(
    commandId: 'seed-category-reversal-income',
    categoryId: CategoryConstants.reversalIncomeId,
    name: l10n.categoryReversalIncome,
    iconKey: '${defaultIcons[31]}',
    colorInt: defaultColors[17].toARGB32(),
    type: CategoryType.income,
    systemCode: CategoryConstants.reversalIncomeCode,
  ));

  // Seed-time currency: fresh install has no preference yet, so the global
  // default applies.
  final currencyCode = AppCurrencies.defaultCurrency.code;
  await _requireSuccess(accountService.createAccount(
    commandId: 'seed-account-cash',
    name: l10n.accountCash,
    type: AccountType.cash,
    initialBalanceMinor: 0,
    currencyCode: currencyCode,
  ));
  await _requireSuccess(accountService.createAccount(
    commandId: 'seed-account-bank',
    name: l10n.accountBankCard,
    type: AccountType.bank,
    initialBalanceMinor: 100000, // 1000.00
    currencyCode: currencyCode,
  ));
}

Future<void> _requireSuccess(Future<Result<void>> result) async {
  if (await result case Failure(:final code, :final message)) {
    throw StateError('Seeding failed: $code — $message');
  }
}
