import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/events/ledger_events.dart';
import '../../domain/queries/get_transaction_history_query.dart';
import '../models/transaction_tile_ui_model.dart';

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

    final currencyKey =
        ref.watch(currencyControllerProvider).value ?? '\$';
    final currency = AppCurrencies.getSymbol(currencyKey);

    final locale = Localizations.localeOf(context).toString();

    // Premium Detail View
    final color = transaction.type == TransactionKind.expense
        ? context.colors.expense
        : context.colors.income;

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
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.cancel,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: l10n.edit,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        SizedBox(width: context.spacing.sm),
                        Text(
                          l10n.delete,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: context.spacing.sm),

          // Amount (Hero)
          Text(
            [
              transaction.type == TransactionKind.expense ? '-' : '+',
              '$currency${transaction.displayAmount}',
            ].join(' '),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.md),

          // Title / Category — transfers have no category (spec US5).
          if (transaction.type != TransactionKind.transfer)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor:
                      Color(transaction.category.colorInt).withValues(alpha: 0.2),
                  foregroundColor: Color(transaction.category.colorInt),
                  child: Icon(
                    IconData(
                      int.tryParse(transaction.category.iconKey) ?? 0xe574,
                      fontFamily: 'MaterialIcons',
                    ),
                    size: 20,
                  ),
                ),
                SizedBox(width: context.spacing.sm),
                Text(
                  transaction.category.name,
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
          ...ref
              .watch(getTransactionHistoryProvider(transaction.id))
              .maybeWhen(
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
}
