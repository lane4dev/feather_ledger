import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/entities/ledger_entities.dart';
import '../theme/ledger_theme.dart';

import 'time_anchor.dart';
import 'transaction_tile.dart';

class LedgerTimeline extends StatelessWidget {
  final Map<DateTime, List<TransactionEntity>> groupedTransactions;
  final String currencySymbol;
  final Function(TransactionEntity)? onTransactionTap;

  const LedgerTimeline({
    super.key,
    required this.groupedTransactions,
    this.currencySymbol = '\$',
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    // We wrap everything in a SliverMainAxisGroup so it acts as a single sliver unit
    // This allows us to use it inside the CustomScrollView's slivers list cleanly.
    return SliverMainAxisGroup(
      slivers: groupedTransactions.entries.map((entry) {
        final date = entry.key;
        final transactions = entry.value;
        return _DayGroup(
          date: date,
          transactions: transactions,
          currencySymbol: currencySymbol,
          onTransactionTap: onTransactionTap,
        );
      }).toList(),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionEntity> transactions;
  final String currencySymbol;
  final Function(TransactionEntity)? onTransactionTap;

  const _DayGroup({
    required this.date,
    required this.transactions,
    required this.currencySymbol,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate daily totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    return SliverMainAxisGroup(
      slivers: [
        // The TimeAnchor is pinned.
        // We set its extent to 0 so it doesn't push the list down.
        // This allows the list to overlap visually with the anchor area.
        SliverPersistentHeader(
          pinned: true,
          delegate: _TimeAnchorDelegate(date: date),
        ),
        SliverList.builder(
          // +1 for the summary row
          itemCount: transactions.length + 1,
          itemBuilder: (context, index) {
            if (index == transactions.length) {
              return _DailySummary(
                income: totalIncome,
                expense: totalExpense,
                currencySymbol: currencySymbol,
              );
            }
            final tx = transactions[index];
            return TransactionTile(
              transaction: tx,
              currencySymbol: currencySymbol,
              onTap: () => onTransactionTap?.call(tx),
            );
          },
        ),
      ],
    );
  }
}

class _TimeAnchorDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;

  // Height of the anchor area. Should match the visual height we want to reserve/display.
  static const double _anchorHeight = 56.0;

  _TimeAnchorDelegate({required this.date});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Align(
      alignment: Alignment.topLeft,
      child: OverflowBox(
        // We allow the child to be its natural size (or fixed height)
        // even though the sliver extent is 0.
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: _anchorHeight,
          // Background color ensures the anchor is readable if content slides under (though here content is indented)
          // Using scaffold background to match.
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TimeAnchor(date: date),
          ),
        ),
      ),
    );
  }

  @override
  // We return a tiny extent (1.0) instead of 0.0 to ensure the RenderObject
  // considers itself visible and paints the child.
  // 0.0 might be optimized out or clipped.
  // The 1.0 pixel offset is visually negligible.
  double get maxExtent => 1.0;

  @override
  double get minExtent => 1.0;

  @override
  bool shouldRebuild(covariant _TimeAnchorDelegate oldDelegate) {
    return oldDelegate.date != date;
  }
}

class _DailySummary extends StatelessWidget {
  final double income;
  final double expense;
  final String currencySymbol;

  const _DailySummary({
    required this.income,
    required this.expense,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: LedgerTheme.colAnchorWidth +
            context.spacing.md, // Match TransactionTile content start
        right: context.spacing.md,
        bottom: context
            .spacing.lg, // Increased bottom spacing for better group separation
        top: context.spacing.sm, // Increased top spacing
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FeatherDivider(),
          Padding(
            padding: EdgeInsets.only(top: context.spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Income
                if (income > 0) ...[
                  Text(
                    'Income: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '+$currencySymbol${income.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.income,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(width: context.spacing.md),
                ],
                // Expense
                if (expense > 0) ...[
                  Text(
                    'Expense: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '-$currencySymbol${expense.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
