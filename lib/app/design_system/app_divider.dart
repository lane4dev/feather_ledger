import 'package:flutter/material.dart';

/// Color and thickness come from the application's DividerTheme.
class AppDivider extends StatelessWidget {
  const AppDivider(
      {super.key, this.height = 1, this.indent = 0, this.endIndent = 0});
  final double height;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: height, indent: indent, endIndent: endIndent);
}
