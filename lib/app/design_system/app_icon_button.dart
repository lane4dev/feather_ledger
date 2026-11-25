import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Toolbar actions share their size and colors; the surface variant is for
/// isolated shortcuts, not every icon on a page.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize,
    this.foregroundColor,
  })  : _surface = false,
        _destructive = false;

  const AppIconButton.surface({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize,
    this.foregroundColor,
  })  : _surface = true,
        _destructive = false;

  const AppIconButton.destructive({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconSize,
    this.foregroundColor,
  })  : _surface = false,
        _destructive = true;

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? iconSize;
  final Color? foregroundColor;
  final bool _surface;
  final bool _destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = context.metrics;
    final color =
        _destructive ? scheme.error : foregroundColor;
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      color: color,
      style: IconButton.styleFrom(
        minimumSize: Size.square(metrics.controlHeight),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: _surface ? scheme.surfaceContainerLow : null,
        shape: _surface
            ? RoundedRectangleBorder(borderRadius: metrics.controlBorderRadius)
            : null,
      ),
    );
  }
}
