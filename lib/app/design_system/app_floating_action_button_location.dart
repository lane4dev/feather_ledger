import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keeps action buttons at the same screen position as the ledger's button,
/// with room for the app's bottom navigation and the system inset.
class AppFloatingActionButtonLocation extends FloatingActionButtonLocation {
  AppFloatingActionButtonLocation(BuildContext context)
      : navigationHeight = NavigationBarTheme.of(context).height ?? 80,
        margin = context.spacing.md;

  final double navigationHeight;
  final double margin;

  @override
  bool operator ==(Object other) =>
      other is AppFloatingActionButtonLocation &&
      other.navigationHeight == navigationHeight &&
      other.margin == margin;

  @override
  int get hashCode => Object.hash(navigationHeight, margin);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final x = FloatingActionButtonLocation.endFloat.getOffset(geometry).dx;
    final bottom = math.max(
      geometry.minViewPadding.bottom + navigationHeight,
      geometry.minInsets.bottom,
    );
    return Offset(
        x,
        geometry.scaffoldSize.height -
            bottom -
            margin -
            geometry.floatingActionButtonSize.height);
  }
}
