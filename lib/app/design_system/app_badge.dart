import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum _AppBadgeVariant { standard, outlined, error }

/// Optional color is user-owned category data, not another app palette.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.color, this.icon})
      : _variant = _AppBadgeVariant.standard,
        _backgroundColor = null;

  /// Status pill with an `outline` border on a tonal surface (e.g. pending bill).
  const AppBadge.outlined({
    super.key,
    required this.label,
    this.icon,
    Color? backgroundColor,
  })  : color = null,
        _variant = _AppBadgeVariant.outlined,
        _backgroundColor = backgroundColor;

  /// High-contrast error pill backed by `errorContainer` / `onErrorContainer`.
  const AppBadge.error({super.key, required this.label, this.icon})
      : color = null,
        _variant = _AppBadgeVariant.error,
        _backgroundColor = null;

  final String label;
  final Color? color;
  final IconData? icon;
  final _AppBadgeVariant _variant;
  final Color? _backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = switch (_variant) {
      _AppBadgeVariant.standard => color == null
          ? scheme.surfaceContainerHigh
          : Color.lerp(scheme.surfaceContainerLow, color, 0.12)!,
      _AppBadgeVariant.outlined =>
        _backgroundColor ?? scheme.surfaceContainerLow,
      _AppBadgeVariant.error => scheme.errorContainer,
    };
    final foreground = switch (_variant) {
      _AppBadgeVariant.standard => scheme.onSurfaceVariant,
      _AppBadgeVariant.outlined => scheme.onSurfaceVariant,
      _AppBadgeVariant.error => scheme.onErrorContainer,
    };
    final borderRadius = switch (_variant) {
      _AppBadgeVariant.standard => context.metrics.chipBorderRadius,
      _AppBadgeVariant.outlined ||
      _AppBadgeVariant.error =>
        BorderRadius.circular(999),
    };
    final BoxBorder? border = _variant == _AppBadgeVariant.outlined
        ? Border.all(color: scheme.outline, width: 1)
        : null;
    final labelText = Text(
      label,
      style: AppTypography.compactLabel(context).copyWith(color: foreground),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm, vertical: context.spacing.xs),
        child: icon == null
            ? labelText
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: foreground),
                  SizedBox(width: context.spacing.xs),
                  Flexible(child: labelText),
                ],
              ),
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({super.key, this.icon, this.child, this.color})
      : assert(icon != null || child != null);
  final IconData? icon;
  final Widget? child;
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
        child:
            child ?? Icon(icon, size: context.metrics.iconSize, color: accent),
      ),
    );
  }
}
