import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/events/ledger_events.dart';
import '../../domain/queries/get_transaction_history_query.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';

import 'ledger_delete_menu.dart';
import 'ledger_detail_row.dart';
import 'ledger_sheet_handle.dart';

class TransactionDetailSheet extends ConsumerWidget {
  final TransactionTileUiModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? currencySymbol;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // The amount below is an amount in this ledger, so it wears the ledger's
    // symbol — the preference can name a currency the accounts are not in.
    final currency = ref.watch(displayCurrencySymbolProvider);

    final locale = Localizations.localeOf(context).toString();

    // Premium Detail View
    // A transfer is neither income nor expense — it gets the neutral
    // onSurface colour, matching transaction_tile.dart (spec 004, FR-005).
    final color = switch (transaction.type) {
      TransactionKind.expense => context.colors.expense,
      TransactionKind.income => context.colors.income,
      TransactionKind.transfer ||
      TransactionKind.openingBalance ||
      TransactionKind.balanceAdjustment =>
        Theme.of(context).colorScheme.onSurface,
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        0,
        context.spacing.lg,
        context.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSheetHandle(),
          // Action Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.cancel,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.squarePen),
                onPressed: onEdit,
                tooltip: l10n.edit,
              ),
              LedgerDeleteMenu(onDelete: () => onDelete?.call()),
            ],
          ),
          SizedBox(height: context.spacing.sm),

          // Amount (Hero). The sign comes from the UI model, which already
          // renders '' for transfers — this used to re-derive it here and
          // showed every transfer with a '+'.
          Text(
            '${transaction.displaySign} $currency${transaction.displayAmount}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.md),

          // A special balance purpose is explicit, never represented by a
          // hidden category. Ordinary categories remain historical snapshots.
          if (transaction.category != null || transaction.type.isBalancePurpose)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (transaction.category != null)
                  CircleAvatar(
                    backgroundColor: Color(transaction.category!.colorInt)
                        .withValues(alpha: 0.2),
                    foregroundColor: Color(transaction.category!.colorInt),
                    child: Icon(
                      CategoryTokens.iconFor(transaction.category!.iconKey),
                      size: 20,
                    ),
                  ),
                if (transaction.category != null)
                  SizedBox(width: context.spacing.sm),
                Text(
                  transaction.category?.name ??
                      _purposeName(l10n, transaction.type),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          SizedBox(height: context.spacing.lg),
          const FeatherDivider(),
          SizedBox(height: context.spacing.md),

          // Details Grid/List
          LedgerDetailRow(
            label: l10n.date,
            value: DateFormat.yMMMMEEEEd(locale).format(transaction.date),
          ),
          if (transaction.type.isBalancePurpose) ...[
            SizedBox(height: context.spacing.md),
            LedgerDetailRow(
              label: l10n.transactionType,
              value: _purposeName(l10n, transaction.type),
            ),
          ],
          SizedBox(height: context.spacing.md),
          if (transaction.type == TransactionKind.transfer &&
              transaction.toAccount != null) ...[
            LedgerDetailRow(
              label: l10n.transferFrom,
              value: transaction.account.name,
            ),
            SizedBox(height: context.spacing.md),
            LedgerDetailRow(
              label: l10n.transferTo,
              value: transaction.toAccount!.name,
            ),
          ] else
            LedgerDetailRow(
              label: l10n.account,
              value: transaction.account.name,
            ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            LedgerDetailRow(
              label: l10n.note,
              value: transaction.note!,
            ),
          ],
          if (transaction.attachments.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            LedgerDetailRow(
              label: l10n.attachments,
              value: transaction.attachments
                  .map((attachment) => attachment.fileName)
                  .join('\n'),
            ),
          ],

          // Audit history (spec 003, US6/T047): the event chain of this
          // transaction — Recorded, plus Reversed with its reason once the
          // transaction is corrected or deleted. Reversed rows are hidden
          // from the list, so the chain is how the UI presents isReversed.
          SizedBox(height: context.spacing.lg),
          const FeatherDivider(),
          SizedBox(height: context.spacing.md),
          Text(
            l10n.auditHistory,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          SizedBox(height: context.spacing.sm),
          ...ref.watch(getTransactionHistoryProvider(transaction.id)).maybeWhen(
                data: (history) => history.map((entry) {
                  final label = entry.eventType == 'TransactionRecorded'
                      ? l10n.eventRecorded
                      : entry.reversalReason == ReversalReason.correction
                          ? '${l10n.eventReversed} · ${l10n.reversalCorrection}'
                          : '${l10n.eventReversed} · ${l10n.reversalUserDeleted}';
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.spacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          DateFormat.yMMMd(locale).format(entry.occurredAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                orElse: () => const [],
              ),
        ],
      ),
    );
  }

  String _purposeName(AppLocalizations l10n, TransactionKind type) =>
      switch (type) {
        TransactionKind.openingBalance => l10n.initialBalance,
        TransactionKind.balanceAdjustment =>
          l10n.accountBalanceAdjustmentDescription,
        _ => '',
      };
}
