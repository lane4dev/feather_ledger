import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum _ButtonVariant { primary, secondary, outlined, dashed, quiet, destructive }

/// The single feature-facing button entry point. It intentionally delegates
/// to Material 3 rather than owning colours or typography.
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final _ButtonVariant _variant;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    bool destructive = false,
    bool outlined = false,
  }) : _variant = outlined
            ? _ButtonVariant.outlined
            : destructive
                ? _ButtonVariant.destructive
                : _ButtonVariant.primary;

  const AppButton.secondary(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.secondary;
  const AppButton.outlined(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.outlined;
  const AppButton.dashed(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.dashed;
  const AppButton.text(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.quiet;
  const AppButton.destructive(
      {super.key, required this.onPressed, required this.child, this.icon})
      : _variant = _ButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final content = icon == null
        ? child
        : Row(mainAxisSize: MainAxisSize.min, children: [
            icon!,
            SizedBox(width: context.spacing.sm),
            Flexible(child: child)
          ]);
    return switch (_variant) {
      _ButtonVariant.primary =>
        FilledButton(onPressed: onPressed, child: content),
      _ButtonVariant.secondary =>
        FilledButton.tonal(onPressed: onPressed, child: content),
      _ButtonVariant.outlined =>
        OutlinedButton(onPressed: onPressed, child: content),
      _ButtonVariant.dashed => CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: onPressed == null
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.38)
                : Theme.of(context).colorScheme.primary,
            borderRadius: context.metrics.chipBorderRadius,
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                  borderRadius: context.metrics.chipBorderRadius),
              padding: EdgeInsets.all(context.spacing.md),
            ),
            child: content,
          ),
        ),
      _ButtonVariant.quiet => TextButton(onPressed: onPressed, child: content),
      _ButtonVariant.destructive => FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
          child: content,
        ),
    };
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = (Offset.zero & size).deflate(paint.strokeWidth / 2);
    final path = Path()..addRRect(borderRadius.toRRect(rect));
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 10) {
        canvas.drawPath(
            metric.extractPath(start, (start + 6).clamp(0, metric.length)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}
