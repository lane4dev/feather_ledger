import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';

import '../models/transaction_tile_ui_model.dart';
import '../theme/ledger_theme.dart';

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

    return AppCard.group(
        child: ListTile(
      onTap: onTap,
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: LedgerTheme.transactionTitle(context),
      ),
      subtitle: Text(
        '$metadata\n$date',
        style: LedgerTheme.transactionMeta(context),
      ),
      isThreeLine: true,
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.4,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${transaction.displaySign} $currencySymbol${transaction.displayAmount}'
                .trim(),
            style: LedgerTheme.transactionAmount(context)
                .copyWith(color: amountColor),
          ),
        ),
      ),
    ));
  }
}
