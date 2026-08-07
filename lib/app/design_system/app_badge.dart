import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Optional color is user-owned category data, not another app palette.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color == null
            ? scheme.surfaceContainerHigh
            : Color.lerp(scheme.surfaceContainerLow, color, 0.12),
        borderRadius: context.metrics.chipBorderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm, vertical: context.spacing.xs),
        child: Text(label,
            style: AppTypography.compactLabel(context)
                .copyWith(color: scheme.onSurfaceVariant)),
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({super.key, required this.icon, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(scheme.surfaceContainerLow, accent, 0.12),
        borderRadius: context.metrics.iconBorderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.metrics.rowInset),
        child: Icon(icon, size: context.metrics.iconSize, color: accent),
      ),
    );
  }
}
