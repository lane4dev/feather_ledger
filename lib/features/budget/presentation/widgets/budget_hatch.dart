import 'package:flutter/material.dart';

/// Diagonal hatching for the plan month's baseline fill.
///
/// A plan baseline is a reference, not money that has moved, so it is drawn as
/// stripes over its own colour token instead of a second solid fill — the
/// prototype asks for a hatched segment, and a hatch also survives being only
/// four dp tall where a lighter tint would read as the actual colour.
///
/// It paints once per layout and never animates, so it costs one [CustomPaint]
/// and changes nothing under reduce-motion.
class BudgetHatch extends StatelessWidget {
  final Color color;

  /// Distance between stripe starts, in logical pixels.
  final double gap;
  final double strokeWidth;

  const BudgetHatch({
    super.key,
    required this.color,
    this.gap = 3,
    this.strokeWidth = 1,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: BudgetHatchPainter(
          color: color,
          gap: gap,
          strokeWidth: strokeWidth,
        ),
      );
}

/// Paints 45° stripes from the bottom-left to the top-right of the box.
class BudgetHatchPainter extends CustomPainter {
  final Color color;
  final double gap;
  final double strokeWidth;

  const BudgetHatchPainter({
    required this.color,
    this.gap = 3,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    // Each stripe is one line `height` long, started every [gap] pixels. The
    // first is offset by a full height so the bottom-left corner is covered
    // before the parent clips the ends.
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BudgetHatchPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.gap != gap ||
      oldDelegate.strokeWidth != strokeWidth;
}
