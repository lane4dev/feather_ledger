import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/tables.dart';
import '../../domain/entities/ledger_entities.dart';
import '../theme/ledger_theme.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionEntity transaction;
  final String currencySymbol;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    // Premium Detail View
    final color = transaction.type == TransactionType.expense
        ? LedgerTheme.expenseColor(context)
        : LedgerTheme.incomeColor(context);

    return Container(
      padding: const EdgeInsets.all(LedgerTheme.gapLg),
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
          const SizedBox(height: LedgerTheme.gapLg),

          // Amount (Hero)
          Text(
            '${transaction.type == TransactionType.expense ? '-' : '+'} $currencySymbol${transaction.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LedgerTheme.gapMd),

          // Title / Category
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconData(int.tryParse(transaction.category.iconKey) ?? 0xe574,
                    fontFamily: 'MaterialIcons'),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: LedgerTheme.gapSm),
              Text(
                transaction.category.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: LedgerTheme.gapLg),
          const Divider(),
          const SizedBox(height: LedgerTheme.gapMd),

          // Details Grid/List
          _DetailRow(
            label: 'Date',
            value: DateFormat.yMMMMEEEEd().format(transaction.date),
          ),
          const SizedBox(height: LedgerTheme.gapMd),
          _DetailRow(
            label: 'Account',
            value: transaction.account.name,
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            const SizedBox(height: LedgerTheme.gapMd),
            _DetailRow(
              label: 'Note',
              value: transaction.note!,
              isLongText: true,
            ),
          ],

          const SizedBox(height: LedgerTheme.gapLg),
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
