import 'package:flutter/material.dart';

/// M3 surface entry point for feature UI. Shape, elevation and colours are
/// read from ThemeData, so callers do not create local visual systems.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Card(
        child: padding == null ? child : Padding(padding: padding!, child: child),
      );
}
