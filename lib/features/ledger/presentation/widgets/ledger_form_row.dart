import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';

/// One line of a form: an icon, the field, and — when the line opens
/// something — a chevron.
///
/// The row is the tap target, not the field inside it. Giving [onTap] here
/// rather than to the child is what makes the icon part of that target: the
/// ripple starts at the row's leading edge instead of wherever the child
/// happens to begin. Nothing else in the row should take a tap of its own, or
/// the row and the child both ripple.
///
/// The row spans the full width its container gives it, and insets its own
/// contents from the page edge. The padding is inside the tap target for that
/// reason: a screen that pads its rows instead of letting them pad themselves
/// clips every ripple one page-margin short of the edge. Anything else the
/// screen puts in the same column is the screen's to pad.
class LedgerFormRow extends StatelessWidget {
  final IconData icon;

  /// What tapping the row does. Null makes an inert row — one that states a
  /// fact (a read-only value) or holds its own input (the note field) — and an
  /// inert row draws no chevron, because a chevron promises an action.
  final VoidCallback? onTap;

  final Widget child;

  const LedgerFormRow({
    super.key,
    required this.icon,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onTap = this.onTap;

    final row = Padding(
      padding: LedgerTheme.pageInset(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, right: 24.0),
            child: Icon(
              icon,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          Expanded(child: child),
          // The icon's padding again: the cross axis is start, so a plain icon
          // would ride level with the top of the field instead of with the
          // text inside it.
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Icon(LucideIcons.chevronRight, color: theme.hintColor),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    // An InkWell clips its splash to its own bounds, so the ripple is exactly
    // this row — from the icon to the chevron — and not the padded contents
    // inside it.
    return InkWell(onTap: onTap, child: row);
  }
}
