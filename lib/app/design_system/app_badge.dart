import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum _AppBadgeVariant { standard, outlined, error }

/// Optional color is user-owned category data, not another app palette.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.compact = false,
  })  : _variant = _AppBadgeVariant.standard,
        _backgroundColor = null;

  /// Status pill with an `outline` border on a tonal surface (e.g. pending bill).
  const AppBadge.outlined({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
    Color? backgroundColor,
  })  : color = null,
        _variant = _AppBadgeVariant.outlined,
        _backgroundColor = backgroundColor;

  /// High-contrast error pill backed by `errorContainer` / `onErrorContainer`.
  const AppBadge.error({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
  })  : color = null,
        _variant = _AppBadgeVariant.error,
        _backgroundColor = null;

  final String label;
  final Color? color;
  final IconData? icon;
  final bool compact;
  final _AppBadgeVariant _variant;
  final Color? _backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final background = switch (_variant) {
      _AppBadgeVariant.standard => color == null
          ? scheme.surfaceContainerHigh
          : Color.lerp(scheme.surfaceContainerLow, color, 0.12)!,
      _AppBadgeVariant.outlined => _backgroundColor ??
          (light ? AppTheme.statusPillSurface : scheme.surfaceContainerLow),
      _AppBadgeVariant.error => scheme.errorContainer,
    };
    final foreground = switch (_variant) {
      _AppBadgeVariant.standard => scheme.onSurfaceVariant,
      _AppBadgeVariant.outlined =>
        light ? AppTheme.statusPillInk : scheme.onSurfaceVariant,
      _AppBadgeVariant.error => scheme.onErrorContainer,
    };
    final borderRadius = switch (_variant) {
      _AppBadgeVariant.standard => context.metrics.chipBorderRadius,
      _AppBadgeVariant.outlined ||
      _AppBadgeVariant.error =>
        BorderRadius.circular(999),
    };
    final BoxBorder? border = _variant == _AppBadgeVariant.outlined
        ? Border.all(
            color: light ? AppTheme.statusPillBorder : scheme.outline,
            width: light ? 0.8 : 1,
          )
        : null;
    final metrics = context.metrics;
    final padding = compact
        ? EdgeInsets.symmetric(
            horizontal: metrics.compactBadgeHorizontalPadding,
            vertical: metrics.compactBadgeVerticalPadding,
          )
        : EdgeInsets.symmetric(
            horizontal: context.spacing.sm,
            vertical: context.spacing.xs,
          );
    final iconSize = compact ? metrics.compactBadgeIconSize : 12.0;

    final labelText = Text(
      label,
      maxLines: compact ? 1 : null,
      softWrap: !compact,
      style: AppTypography.compactLabel(context).copyWith(color: foreground),
    );
    final content = Padding(
      padding: padding,
      child: icon == null
          ? labelText
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: foreground),
                SizedBox(width: context.spacing.xs),
                Flexible(child: labelText),
              ],
            ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        border: border,
      ),
      child: compact
          ? ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: metrics.compactBadgeMinHeight,
              ),
              child: Center(widthFactor: 1.0, child: content),
            )
          : content,
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
