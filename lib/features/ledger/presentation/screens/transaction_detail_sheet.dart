import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/tables.dart';
import '../../../../shared/presentation/widgets/feather_divider.dart';
import '../../domain/entities/ledger_entities.dart';

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
        context.spacing.sm,
        context.spacing.lg,
        context.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

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
                tooltip: 'Edit',
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
            '${transaction.type == TransactionType.expense ? '-' : '+'} $currencySymbol${transaction.amount.toStringAsFixed(2)}',
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
          _DetailRow(
            label: 'Date',
            value: DateFormat.yMMMMEEEEd().format(transaction.date),
          ),
          SizedBox(height: context.spacing.md),
          _DetailRow(
            label: 'Account',
            value: transaction.account.name,
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            _DetailRow(
              label: 'Note',
              value: transaction.note!,
              isLongText: true,
            ),
          ],

          SizedBox(height: context.spacing.lg),
          // Close Button (Optional, standard sheet swipe is fine)
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLongText;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLongText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
