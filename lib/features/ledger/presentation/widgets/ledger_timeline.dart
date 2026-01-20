import 'package:flutter/material.dart';
import '../../domain/entities/ledger_entities.dart';
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
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _TimeAnchorDelegate(date: date),
        ),
        SliverList.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
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

  _TimeAnchorDelegate({required this.date});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // The anchor is on the left. The right side is transparent to let list content scroll under?
    // Wait. If list content scrolls UNDER the pinned header, and the header is transparent on the right,
    // then we see the list content through the header space.
    // BUT the list content (TransactionTile) has a 72dp Spacer on the left.
    // So the list content is actually shifted right.
    // So "under" the header on the left is just empty space (the spacer).
    // "Under" the header on the right is the TransactionTile content.
    // So if the header is transparent on the right, we see the scrolling content.
    // This is EXACTLY what we want: Content scrolls up, Anchor pins.
    // When the next group comes, its header pushes the current header up.
    
    // One issue: The Header background.
    // If the header has NO background, then as items scroll under it (in the spacer area), it's fine.
    // But the Anchor text itself needs to be visible.
    // Usually we want the Anchor to have a background matching the Scaffold background so items don't show *through* the text.
    // But the items are shifted right! So no items are ever behind the Anchor Text.
    // So transparent background is safe?
    // Yes, because `TransactionTile` has `SizedBox(width: 72)`.
    // The `TimeAnchor` is `width: 72`.
    // So they share the vertical column but strictly separate horizontally.
    // So items will scroll "beside" the pinned anchor.
    // Visual check:
    // [Pinned Anchor] [Scrolling Item 1]
    //                 [Scrolling Item 2]
    // 
    // Wait, `SliverPersistentHeader` sits ON TOP of the viewport until pushed.
    // Does `SliverMainAxisGroup` put the List *visually below* the Header in layout (Y-axis)?
    // Yes, `SliverMainAxisGroup` arranges slivers vertically.
    // So:
    // [Header]
    // [List]
    // When scrolling, Header stays at top. List scrolls up and disappears "behind" or "under" the Header rect?
    // In Flutter, pinned headers stack on top of scrolling content.
    // So the List items scroll UP and go BEHIND the Pinned Header.
    // Since our Header is transparent on the right, we see the items scrolling "through" the header space on the right.
    // Since our Items have a Spacer on the left, nothing scrolls "behind" the Anchor Text on the left.
    // So this works perfectly.
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor, // Opaque bg for anchor to hide previous group's spacer?
        // Actually, previous group's spacer is empty.
        // But if we have separators or background colors on tiles?
        // Safest is to have opaque background for the Anchor column area.
        child: TimeAnchor(date: date),
      ),
    );
  }

  @override
  double get maxExtent => 56.0; // Estimate height of TimeAnchor

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _TimeAnchorDelegate oldDelegate) {
    return oldDelegate.date != date;
  }
}
