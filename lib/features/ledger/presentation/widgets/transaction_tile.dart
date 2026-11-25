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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSkipped = transaction.isSkipped;
    final isFailed = transaction.isFailed;

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
                  // Pending/failed/skipped bills get an icon so the row
                  // announces its state even before opacity or badge registers.
                  Row(
                    children: [
                      if (transaction.isPending) ...[
                        Icon(
                          isFailed
                              ? LucideIcons.triangleAlert
                              : (isSkipped
                                  ? LucideIcons.circlePause
                                  : LucideIcons.clock),
                          size: 16.0,
                          color: isFailed
                              ? theme.colorScheme.error
                              : LedgerTheme.transactionMeta(context).color,
                        ),
                        const SizedBox(width: 4.0),
                      ],
                      Expanded(
                        child: Text(
                          _title(context),
                          style: LedgerTheme.transactionTitle(context).copyWith(
                            decoration:
                                isSkipped ? TextDecoration.lineThrough : null,
                          ),
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
                            _statusBadge(context, l10n, theme),
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
              transaction.formattedAmount(effectiveCurrencySymbol),
              style: LedgerTheme.transactionAmount(context).copyWith(
                decoration: isSkipped ? TextDecoration.lineThrough : null,
                color: switch (transaction.type) {
                  TransactionKind.expense => context.colors.expense,
                  TransactionKind.income => context.colors.income,
                  TransactionKind.transfer ||
                  TransactionKind.openingBalance ||
                  TransactionKind.balanceAdjustment =>
                    theme.colorScheme.onSurface,
                },
              ),
            ),
          ],
        ),
      ),
    );

    // Pending/skipped/failed rows are muted as a whole rather than restyled
    // piece by piece. Posted rows — the common case — skip the extra layer.
    if (!transaction.isPending) return row;
    final opacity = isSkipped ? 0.45 : (isFailed ? 0.85 : 0.55);
    return Opacity(opacity: opacity, child: row);
  }

  /// The scheduled status tag (`待入账` / `已跳过` / `自动入账失败`).
  Widget _statusBadge(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (transaction.isSkipped) {
      return AppBadge(label: l10n.skippedBill);
    }
    if (transaction.isFailed) {
      return AppBadge(
        label: l10n.failedBill,
        color: theme.colorScheme.error,
      );
    }
    return AppBadge(label: l10n.pendingBill);
  }

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
