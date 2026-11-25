import 'package:feather_ledger/shared/presentation/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';

import '../models/transaction_tile_ui_model.dart';

/// A search hit, adapted into the shared transaction row.
///
/// The row itself carries no card: search groups hits by month and wraps each
/// month in one surface. This adapter only decides what the row says — the
/// note (or category, or kind) as the title, the category and account as the
/// metadata, and a date that drops the year while it is still the current one.
class SearchTransactionTile extends StatelessWidget {
  const SearchTransactionTile({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.onTap,
    this.highlightQuery,
  });

  final TransactionTileUiModel transaction;
  final String currencySymbol;
  final VoidCallback onTap;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kindLabel = switch (transaction.type) {
      TransactionKind.income => l10n.income,
      TransactionKind.expense => l10n.expense,
      TransactionKind.transfer => l10n.transfer,
      TransactionKind.openingBalance => l10n.initialBalance,
      TransactionKind.balanceAdjustment =>
        l10n.accountBalanceAdjustmentDescription,
    };
    final title = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!
        : transaction.category?.name ?? kindLabel;
    final accountLabel = transaction.toAccount == null
        ? transaction.account.name
        : '${transaction.account.name} → ${transaction.toAccount!.name}';
    final amountColor = switch (transaction.type) {
      TransactionKind.income => context.colors.income,
      TransactionKind.expense => context.colors.expense,
      _ => Theme.of(context).colorScheme.onSurface,
    };

    return TransactionListTile(
      onTap: onTap,
      title: title,
      amount: transaction.formattedAmount(currencySymbol),
      amountColor: amountColor,
      categoryName: transaction.category?.name,
      categoryIconKey: transaction.category?.iconKey,
      categoryColor: transaction.category == null
          ? null
          : Color(transaction.category!.colorInt),
      accountLabel: accountLabel,
      dateText: formatSearchDate(context, transaction.date),
      showCategoryIcon: true,
      showCategoryName: transaction.category != null,
      highlightQuery: highlightQuery,
    );
  }

  /// `11/24 12:30` while the hit is in the current year, `2025/11/24` once it
  /// is not — the year only earns its space when it distinguishes something.
  static String formatSearchDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final format = date.year == now.year
        ? DateFormat.Md(locale).add_Hm()
        : DateFormat.yMd(locale);
    return format.format(date);
  }
}
