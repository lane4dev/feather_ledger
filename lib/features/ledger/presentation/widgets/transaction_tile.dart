import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:flutter/material.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/transaction_tile_ui_model.dart';
import '../theme/ledger_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionTileUiModel transaction;
  final VoidCallback? onTap;
  final String? currencySymbol;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCurrencySymbol =
        currencySymbol ?? AppCurrencies.defaultCurrency.symbol;

    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.sm,
        ),
        child: Row(
          children: [
            const SizedBox(width: LedgerTheme.colAnchorWidth),

            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: Note if exists, else Account (transfer shows its
                  // localized label with both sides in the subtitle).
                  // A pending bill gets a clock so the row announces itself
                  // even before the muted opacity registers.
                  Row(
                    children: [
                      if (transaction.isPending) ...[
                        Icon(
                          LucideIcons.clock,
                          size: 16.0,
                          color: LedgerTheme.transactionMeta(context).color,
                        ),
                        const SizedBox(width: 4.0),
                      ],
                      Expanded(
                        child: Text(
                          _title(context),
                          style: LedgerTheme.transactionTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Subtitle: Account (only if note was the title)
                  if (_subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        _subtitle!,
                        style: LedgerTheme.transactionMeta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Ordinary transactions have a category. Transfers and
                  // balance purposes intentionally do not.
                  if (transaction.category != null || transaction.isPending)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          if (transaction.category != null)
                            AppBadge(
                                label: transaction.category!.name,
                                color: Color(transaction.category!.colorInt)),
                          if (transaction.isPending) ...[
                            if (transaction.type != TransactionKind.transfer)
                              const SizedBox(width: 6.0),
                            _pendingBadge(context),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: context.spacing.md),

            // Amount — transfers are neutral (net zero, spec US5).
            Text(
              '${transaction.displaySign} $effectiveCurrencySymbol${transaction.displayAmount}',
              style: LedgerTheme.transactionAmount(context).copyWith(
                color: switch (transaction.type) {
                  TransactionKind.expense => context.colors.expense,
                  TransactionKind.income => context.colors.income,
                  TransactionKind.transfer ||
                  TransactionKind.openingBalance ||
                  TransactionKind.balanceAdjustment =>
                    Theme.of(context).colorScheme.onSurface,
                },
              ),
            ),
          ],
        ),
      ),
    );

    // A pending bill is muted as a whole rather than restyled piece by piece:
    // one dial to turn, and it reads as "not yet" at a glance without
    // changing any of the colours the row's meaning depends on. Posted rows
    // — the common case — skip the extra layer entirely.
    return transaction.isPending ? Opacity(opacity: 0.55, child: row) : row;
  }

  /// The "waiting to be posted" tag. Same pill shape as the category tag so
  /// the row keeps one visual language.
  Widget _pendingBadge(BuildContext context) =>
      AppBadge(label: AppLocalizations.of(context)!.pendingBill);

  String _title(BuildContext context) {
    final hasNote = transaction.note != null && transaction.note!.isNotEmpty;
    if (hasNote) return transaction.note!;
    if (transaction.type == TransactionKind.transfer) {
      return AppLocalizations.of(context)!.transfer;
    }
    if (transaction.type == TransactionKind.openingBalance) {
      return AppLocalizations.of(context)!.initialBalance;
    }
    if (transaction.type == TransactionKind.balanceAdjustment) {
      return AppLocalizations.of(context)!.accountBalanceAdjustmentDescription;
    }
    return transaction.account.name;
  }

  String? get _subtitle {
    final hasNote = transaction.note != null && transaction.note!.isNotEmpty;
    if (transaction.type == TransactionKind.transfer &&
        transaction.toAccount != null) {
      return '${transaction.account.name} → ${transaction.toAccount!.name}';
    }
    if (hasNote) return transaction.account.name;
    return null;
  }
}
