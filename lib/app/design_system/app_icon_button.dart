import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Toolbar actions share their size and colors; the surface variant is for
/// isolated shortcuts, not every icon on a page.
class AppIconButton extends StatelessWidget {
  const AppIconButton(
      {super.key, required this.icon, this.onPressed, this.tooltip})
      : _surface = false,
        _destructive = false;
  const AppIconButton.surface(
      {super.key, required this.icon, this.onPressed, this.tooltip})
      : _surface = true,
        _destructive = false;

  const AppIconButton.destructive(
      {super.key, required this.icon, this.onPressed, this.tooltip})
      : _surface = false,
        _destructive = true;

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool _surface;
  final bool _destructive;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
        color: _destructive ? Theme.of(context).colorScheme.error : null,
        style: _surface
            ? IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                    borderRadius: context.metrics.controlBorderRadius),
              )
            : null,
      );
}
