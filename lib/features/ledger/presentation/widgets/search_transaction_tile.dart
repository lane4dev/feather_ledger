import 'package:feather_ledger/shared/presentation/widgets/transaction_result_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';

import '../models/transaction_tile_ui_model.dart';

/// A standalone search result, including its date and both transfer accounts.
class SearchTransactionTile extends StatelessWidget {
  const SearchTransactionTile({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.onTap,
  });

  final TransactionTileUiModel transaction;
  final String currencySymbol;
  final VoidCallback onTap;

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
    final accounts = transaction.toAccount == null
        ? transaction.account.name
        : '${transaction.account.name} → ${transaction.toAccount!.name}';
    final metadata = [
      kindLabel,
      if (transaction.category != null) transaction.category!.name,
      accounts,
    ].join(' · ');
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMd(locale).add_Hm().format(transaction.date);
    final amountColor = switch (transaction.type) {
      TransactionKind.income => context.colors.income,
      TransactionKind.expense => context.colors.expense,
      _ => Theme.of(context).colorScheme.onSurface,
    };

    return TransactionResultCard(
      onTap: onTap,
      title: title,
      metadata: metadata,
      date: date,
      amount: transaction.formattedAmount(currencySymbol),
      amountColor: amountColor,
    );
  }
}
