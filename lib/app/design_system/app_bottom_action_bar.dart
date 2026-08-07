import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Forms and sheet actions share width, height, safe areas and keyboard motion.
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedPadding(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(
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
