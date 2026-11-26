import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';

/// One transaction row, framed by its host.
///
/// The row owns the two-line anatomy every transaction list shares — title,
/// one metadata line, and a right-aligned amount — but never a card. Grouped
/// lists put the card and the hairline separators around it, so a search
/// result, a budget contribution, and any later list read the same.
///
/// The amount already carries the direction: an expense is negative and
/// expenses are coloured. Nothing here prefixes "Expense · " to the metadata;
/// that would say the same thing twice.
class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    super.key,
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.onTap,
    this.categoryName,
    this.categoryIconKey,
    this.categoryColor,
    this.accountLabel,
    this.dateText,
    this.dateFirst = false,
    this.showCategoryIcon = false,
    this.showCategoryName = true,
    this.highlightQuery,
    this.trailingTags = const [],
    this.dense = false,
  });

  static const double iconBubbleSize = 40;

  final String title;
  final String amount;
  final Color amountColor;
  final VoidCallback onTap;

  /// The category's display name, used when [showCategoryName] is true.
  final String? categoryName;

  /// The persisted icon key; `null` falls back to the palette default.
  final String? categoryIconKey;

  /// The category's palette colour, drawn behind the icon.
  final Color? categoryColor;

  /// The account, or `Cash → Bank` for a transfer.
  final String? accountLabel;

  /// Formatted by the host: `11/24 12:30` within the year, `2025/11/24` across
  /// it, or the budget's day label.
  final String? dateText;

  /// Puts the date before the account (`11/29 18:30 · Cash`) instead of after
  /// it. The search page reads category → account → date; the budget detail's
  /// one-category rows lead with the date.
  final bool dateFirst;

  final bool showCategoryIcon;
  final bool showCategoryName;

  /// When non-empty, occurrences in the title are tinted `primary` and set
  /// semibold. Case-insensitive; the query is trimmed first.
  final String? highlightQuery;

  /// Lightweight status pills (`Fixed`, `Pending`) that sit on the metadata
  /// line instead of taking a third one.
  final List<Widget> trailingTags;

  /// Tightens the vertical padding from 12 dp to 9 dp. Used by the budget
  /// contributions page, whose rows must read as a dense ledger (60–64 dp)
  /// rather than search results.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final metaStyle = AppTypography.meta(context);
    final subtitle = [
      if (showCategoryName && categoryName != null) categoryName!,
      if (dateFirst && dateText != null) dateText!,
      if (accountLabel != null) accountLabel!,
      if (!dateFirst && dateText != null) dateText!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.metrics.compactGutter,
          vertical: dense ? 9 : context.metrics.rowInset,
        ),
        child: Row(
          children: [
            if (showCategoryIcon) ...[
              _CategoryBubble(
                iconKey: categoryIconKey,
                color: categoryColor ?? scheme.onSurfaceVariant,
              ),
              SizedBox(width: spacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    _highlighted(
                      title,
                      Theme.of(context).textTheme.bodyLarge,
                      query: highlightQuery,
                      hit: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty || trailingTags.isNotEmpty) ...[
                    SizedBox(height: spacing.xs / 2),
                    // One line while it fits; on a 320 dp screen at 1.6x text
                    // the badges move to a second metadata line instead of
                    // overflowing the row.
                    Wrap(
                      spacing: spacing.xs,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (subtitle.isNotEmpty)
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: metaStyle),
                        ...trailingTags,
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: spacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(amount,
                    style: AppTypography.amount(context)
                        .copyWith(color: amountColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Splits [text] around every case-insensitive occurrence of the query.
  ///
  /// A blank query returns the plain span, so a host can pass the field's raw
  /// value without testing it first.
  static TextSpan _highlighted(String text, TextStyle? base,
      {required TextStyle hit, String? query}) {
    final needle = query?.trim() ?? '';
    if (needle.isEmpty) return TextSpan(text: text, style: base);
    final lower = text.toLowerCase();
    final match = needle.toLowerCase();
    if (!lower.contains(match)) return TextSpan(text: text, style: base);

    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = lower.indexOf(match, start);
      if (index < 0) break;
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + match.length),
        style: base?.merge(hit),
      ));
      start = index + match.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return TextSpan(style: base, children: spans);
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.iconKey, required this.color});

  final String? iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: TransactionListTile.iconBubbleSize,
      height: TransactionListTile.iconBubbleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(scheme.surfaceContainerLow, color, 0.14),
      ),
      alignment: Alignment.center,
      child: CategoryIcon(
        iconKey: iconKey ?? '',
        size: context.metrics.iconSize,
        color: color,
      ),
    );
  }
}
