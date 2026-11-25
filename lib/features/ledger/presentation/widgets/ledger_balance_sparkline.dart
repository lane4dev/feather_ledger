import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/ledger_expense_trend.dart';

/// The overview card's right-hand flourish: the month's daily spending as a
/// single smooth line, with a soft fill beneath it.
///
/// No axes, no grid, no labels — it is a texture that says "spending moved
/// like this", not a chart anyone reads values off. The numbers are already
/// on the card; a scale beside them would be a second, smaller answer.
class LedgerBalanceSparkline extends StatelessWidget {
  final LedgerExpenseTrend trend;
  final Color lineColor;
  final Color axisHintColor;
  final double width;
  final double height;

  const LedgerBalanceSparkline({
    super.key,
    required this.trend,
    required this.lineColor,
    required this.axisHintColor,
    this.width = 88,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: null,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparklinePainter(
            points: trend.points,
            lineColor: lineColor,
            axisHintColor: axisHintColor,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.points,
    required this.lineColor,
    required this.axisHintColor,
  });

  final List<double> points;
  final Color lineColor;
  final Color axisHintColor;

  /// Vertical breathing room so a 2dp stroke is never cut by the box edge.
  static const double _inset = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final peak = points.isEmpty ? 0.0 : points.reduce(math.max);
    // Two points is the minimum that can be a line, and an all-zero series has
    // no shape: drawing it would be a straight rise from nothing.
    if (points.length < 2 || peak <= 0) {
      _paintDashedBaseline(canvas, size);
      return;
    }

    final usableHeight = math.max(1.0, size.height - _inset * 2);
    final stepX = size.width / (points.length - 1);
    final vertices = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          stepX * i,
          _inset + usableHeight * (1 - points[i] / peak),
        ),
    ];

    final line = _smoothedPath(vertices);
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, _inset),
          Offset(0, size.height),
          [
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0),
          ],
        ),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  /// A Catmull-Rom spline expressed as cubic Béziers: each segment's control
  /// points follow the neighbours, so the line bends through every day rather
  /// than kinking at it.
  Path _smoothedPath(List<Offset> vertices) {
    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (var i = 0; i < vertices.length - 1; i++) {
      final p0 = i == 0 ? vertices[i] : vertices[i - 1];
      final p1 = vertices[i];
      final p2 = vertices[i + 1];
      final p3 = i + 2 < vertices.length ? vertices[i + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  /// What a month with nothing to draw still shows: a whisper of a line where
  /// the curve would have been, so the card keeps its shape instead of
  /// collapsing into empty space.
  void _paintDashedBaseline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = axisHintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final y = size.height - _inset;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.axisHintColor != axisHintColor ||
      !_samePoints(oldDelegate.points, points);

  static bool _samePoints(List<double> a, List<double> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
