import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/entities/ledger_entities.dart';
import '../widgets/ledger_detail_row.dart';
import '../widgets/ledger_sheet_handle.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionEntity transaction;
  final String currencySymbol;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.currencySymbol = '\$',
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Premium Detail View
    final color = transaction.type == TransactionType.expense
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
              transaction.type == TransactionType.expense ? '-' : '+',
              '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
            ].join(' '),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.md),

          // Title / Category
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconData(int.tryParse(transaction.category.iconKey) ?? 0xe574,
                    fontFamily: 'MaterialIcons'),
                color: Theme.of(context).colorScheme.primary,
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
            value: DateFormat.yMMMMEEEEd().format(transaction.date),
          ),
          SizedBox(height: context.spacing.md),
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

          SizedBox(height: context.spacing.lg),
          // Close Button (Optional, standard sheet swipe is fine)
        ],
      ),
    );
  }
}
