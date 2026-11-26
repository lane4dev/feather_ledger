import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Forms and sheet actions share width, height, safe areas and keyboard motion.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({super.key, required this.child, this.padding});
  final Widget child;

  /// Overrides the page gutter; the keyboard inset is the caller's to add.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => AnimatedPadding(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
        padding: padding ??
            EdgeInsets.fromLTRB(
              context.pagePadding.left,
              context.spacing.sm,
              context.pagePadding.right,
              MediaQuery.viewInsetsOf(context).bottom + context.spacing.sm,
            ),
        child: SafeArea(
          top: false,
          child: SizedBox(
              height: context.metrics.actionHeight,
              width: double.infinity,
              child: child),
        ),
      );
}
