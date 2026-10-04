import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A floating surface for contextual controls above scrollable content.
class AppFloatingToolbar extends StatelessWidget {
  const AppFloatingToolbar({
    super.key,
    required this.child,
  });

  final Widget child;
  static const _compactWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: context.metrics.subtleElevation,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(
            MediaQuery.sizeOf(context).width - context.spacing.lg * 2,
            _compactWidth *
                math.max(1, MediaQuery.textScalerOf(context).scale(1)),
          ),
          minHeight: context.metrics.controlHeight,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.spacing.xs / 2),
          child: child,
        ),
      ),
    );
  }
}
