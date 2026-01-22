import 'package:flutter/material.dart';

/// A consistent, subtle divider used throughout the application.
///
/// Uses [Theme.of(context).dividerColor] with 10% opacity for a minimalist look.
class FeatherDivider extends StatelessWidget {
  final double height;
  final double indent;
  final double endIndent;

  const FeatherDivider({
    super.key,
    this.height = 1,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      height: height,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
