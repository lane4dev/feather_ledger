import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A weak shared surface with no outline or internal separators.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl(
      {super.key,
      required this.segments,
      required this.selected,
      required this.onSelected,
      this.widthFactor});
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = context.metrics;
    final control = DecoratedBox(
      decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: metrics.controlBorderRadius),
      child: ClipRRect(
        borderRadius: metrics.controlBorderRadius,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.xs / 2),
          child: SegmentedButton<T>(
            segments: segments,
            selected: {selected},
            onSelectionChanged: (values) => onSelected(values.first),
            showSelectedIcon: false,
            expandedInsets: widthFactor == null ? null : EdgeInsets.zero,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? scheme.secondaryContainer
                      : scheme.surface.withValues(alpha: 0)),
              foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.disabled)
                      ? scheme.onSurface.withValues(alpha: 0.38)
                      : states.contains(WidgetState.selected)
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant),
              side: const WidgetStatePropertyAll(BorderSide.none),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: metrics.selectionBorderRadius)),
              textStyle:
                  WidgetStatePropertyAll(Theme.of(context).textTheme.bodyLarge),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
                  horizontal: context.spacing.md,
                  vertical: context.spacing.sm)),
              minimumSize:
                  WidgetStatePropertyAll(Size.square(metrics.controlHeight)),
            ),
          ),
        ),
      ),
    );
    return Center(
        child: widthFactor == null
            ? control
            : FractionallySizedBox(widthFactor: widthFactor, child: control));
  }
}
