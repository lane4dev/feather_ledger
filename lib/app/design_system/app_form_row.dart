import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// The whole row owns the tap target; padding stays inside its ink response.
class AppFormRow extends StatelessWidget {
  const AppFormRow(
      {super.key,
      this.icon,
      required this.child,
      this.onTap,
      this.showChevron = true})
      : _page = false,
        _card = false;
  const AppFormRow.page(
      {super.key,
      required this.icon,
      required this.child,
      this.onTap,
      this.showChevron = true})
      : _page = true,
        _card = false;

  /// A row inside a grouped card: 16 dp side padding, a 12 dp icon gap, and
  /// no page margin — the card already supplies the edge.
  const AppFormRow.card(
      {super.key,
      this.icon,
      required this.child,
      this.onTap,
      this.showChevron = true})
      : _page = false,
        _card = true;
  final IconData? icon;
  final Widget child;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool _page;
  final bool _card;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: _page
          ? context.pagePadding
          : _card
              ? EdgeInsets.symmetric(horizontal: context.spacing.md)
              : EdgeInsets.zero,
      child: Row(
          crossAxisAlignment:
              _page ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Padding(
                padding: _page
                    ? EdgeInsets.only(right: context.metrics.pageGutter)
                    : _card
                        ? EdgeInsets.only(right: context.spacing.md)
                        : context.metrics.formIconPadding,
                child: Icon(icon,
                    size: context.metrics.iconSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            Expanded(child: child),
            if (onTap != null && showChevron)
              Padding(
                padding: EdgeInsets.only(
                    top: _page ? 0 : context.metrics.rowInset,
                    left: context.spacing.xs),
                child: Icon(LucideIcons.chevronRight,
                    size: context.metrics.iconSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ]),
    );
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}
