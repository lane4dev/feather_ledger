import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// The whole row owns the tap target; padding stays inside its ink response.
class AppFormRow extends StatelessWidget {
  const AppFormRow(
      {super.key,
      required this.icon,
      required this.child,
      this.onTap,
      this.showChevron = true})
      : _page = false;
  const AppFormRow.page(
      {super.key,
      required this.icon,
      required this.child,
      this.onTap,
      this.showChevron = true})
      : _page = true;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool _page;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: _page ? context.pagePadding : EdgeInsets.zero,
      child: Row(
          crossAxisAlignment:
              _page ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: _page
                  ? EdgeInsets.only(right: context.metrics.pageGutter)
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
