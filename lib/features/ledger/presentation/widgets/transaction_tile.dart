import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/database/tables.dart';

import '../../domain/entities/ledger_entities.dart';
import '../theme/ledger_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final String currencySymbol;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.sm,
        ),
        child: Row(
          children: [
            // Left spacer to align with header anchor (if needed, but tile is inside list content)
            // Actually, the TimeAnchor is outside this tile in the layout plan.
            // This tile is just the content content.
            // But wait, the plan says:
            // "Left: Time Anchor Placeholder (invisible/spacer to align content)"
            // "Center: Title (Text), Meta (Category icon + name)"
            // "Right: Amount (Colored + Sign)"

            // Checking the visual reference and plan again.
            // The TimeAnchor is in a separate column in the SliverPersistentHeader (or pinned side).
            // However, to keep the content aligned if the anchor is sticky *next* to it?
            // "Header and Time Anchor must never overlap; main content column alignment remains consistent."
            // In the "Native Slivers" plan (Option B), the Time Anchor is in a SliverPersistentHeader.
            // The SliverPersistentHeader pushes content down? No, it sits on top.
            // If we use SliverMainAxisGroup:
            // [Header (Anchor)]
            // [List (Transactions)]
            // The Anchor is a header for the group. It spans the width.
            // But the design often has the anchor on the LEFT of the list items.
            // If the anchor is a header, it's typically above.
            // If we want it on the left (timeline style), we usually have a Row.
            // BUT, strictly sticky left column is hard with native Slivers unless it's a Table or we use a clever layout.
            // Plan says: "TimeAnchor: The left column widget... TransactionTile: Left: Time Anchor Placeholder (invisible/spacer to align content)."
            // This implies the TransactionTile needs to reserve space for the anchor IF the anchor is overlaying or if the anchor is visually in the same row.

            // Wait, Option B says: "SliverPersistentHeader (Pinned): Displays the TimeAnchor. SliverList: Displays the transactions".
            // If the header is pinned, it stays at the top. The list scrolls under it.
            // If the design is a "Left Rail" time anchor, then standard SliverPersistentHeader (which is full width top-to-bottom) might not be exactly right unless the header CONTENT is just the left part and allows touch-through (unlikely).
            // OR, the Header contains the Anchor for the *group*.
            // Let's assume the "Time Anchor" is a Section Header that visually looks like a side rail?
            // Re-reading spec: "Introduce a left-side Time Anchor that stays visible during scroll... default grouping By Day".
            // "Anchor Switching Rule: active Time Anchor defined by first visible item".

            // If I use SliverPersistentHeader, it occupies vertical space.
            // If I want it to look like it's on the left, I need the content to be indented.
            // So:
            // Header: [ Anchor Widget ] (Height = X, Width = 100%) - But transparent bg on the right?
            // List Item: [ Spacer (Width = Anchor Width) ] [ Content ]
            // This way, the pinned header sits "over" the spacers of the scrolling list items?
            // Or the Header is just a row with the date, and items are below?
            // "A left-side Time Anchor that stays visible during scroll" strongly implies a side-rail design (like Google Tasks or a timeline).

            // Implementation Strategy:
            // The `SliverPersistentHeader` will contain the `TimeAnchor` widget aligned to the left.
            // It will have a transparent background so list items *could* be seen behind it if they weren't offset.
            // BUT `SliverPersistentHeader` pushes content down in the main axis (vertical). It doesn't overlay.
            // UNLESS we use `SliverOverlapInjector`? No, that's for app bars.
            // Actually, if it pushes content down, then it's a standard section header (like "Monday, Jan 20" above the items).
            // But the user wants a "Left-side Time Anchor".

            // If the plan is "Option B: Native Slivers with Pinned Headers", and the goal is a left-side anchor:
            // We usually treat the "Day" as a section. The header is the Day.
            // To make it look "Left Side", the header might just be the "20 Mon" text, and the items are indented.
            // BUT standard sticky headers sit *above* the items.
            // If the design requires the anchor to be *beside* the first item and then stick?
            // Or just stick at the top of the group?
            // "Pinned left-side Time Anchor... always know which time group I'm looking at".

            // Let's stick to the Plan's "TransactionTile" definition:
            // "Left: Time Anchor Placeholder (invisible/spacer to align content)."
            // This confirms we need indentation in the tile.

            // And the Header?
            // If it's a `SliverPersistentHeader`, it will sit *above* the list of tiles.
            // This means visual gap between groups?
            // Or maybe the Header is *just* the Anchor, and it overlaps?
            // Standard Flutter `SliverPersistentHeader` takes layout space. It doesn't overlay.
            // If we want a true "Left Rail" sticky anchor, we might need a stack or a specialized package.
            // But "No new deps".

            // Workaround for "Left Side" look using standard Headers:
            // The Header is the "Day 20" row.
            // The List Items are indented.
            // This looks like a header *above* items.
            // If the user strictly wants it *to the left* (timeline), then the Header needs to be 0-height? Impossible.
            // OR the design is:
            // [Header: 20 Mon]
            // [Item 1       ]
            // [Item 2       ]
            // This is standard.

            // Let's assume the "Google Tasks" reference implies the standard Section Header approach,
            // OR the "Timeline" approach where the header is transparent and allows items to slide under,
            // but that's hard with standard slivers.

            // Let's follow the Plan: "TransactionTile: Left: Time Anchor Placeholder".
            // And "TimeAnchor: The left column widget".
            // If the Header is pinned, it will stay at the top.
            // If the tile has a placeholder, it reserves space.
            // This implies the Header *also* has the anchor on the left, and is transparent/empty on the right?
            // But it still pushes items down.

            // Let's implement the tile with the indentation first.

            const SizedBox(width: LedgerTheme.colAnchorWidth),

            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: Note if exists, else Account
                  Text(
                    (transaction.note != null && transaction.note!.isNotEmpty)
                        ? transaction.note!
                        : transaction.account.name,
                    style: LedgerTheme.transactionTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Subtitle: Account (only if note was the title)
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        transaction.account.name,
                        style: LedgerTheme.transactionMeta(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Category Tag
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        transaction.category.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: context.spacing.md),

            // Amount
            Text(
              '${transaction.type == TransactionType.expense ? '-' : '+'} $currencySymbol${transaction.amount.toStringAsFixed(2)}',
              style: LedgerTheme.transactionAmount(context).copyWith(
                color: transaction.type == TransactionType.expense
                    ? context.colors.expense
                    : context.colors.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
