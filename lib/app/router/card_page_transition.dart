import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';

/// The card is measured again on return, so a missing or off-screen source
/// can fall back to a fade instead of collapsing to an obsolete position.
class CardPageOrigin {
  const CardPageOrigin(this.month, this.sourceKey);

  final DateTime month;
  final GlobalKey? sourceKey;
}

class CardPageTransition extends StatelessWidget {
  const CardPageTransition({
    super.key,
    required this.animation,
    required this.sourceKey,
    required this.child,
  });

  final Animation<double> animation;
  final GlobalKey? sourceKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final pageRect = Offset.zero & size;
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final source = sourceKey?.currentContext?.findRenderObject();
          final overlay = context.findRenderObject();
          Rect? sourceRect;
          if (source is RenderBox &&
              source.attached &&
              source.hasSize &&
              overlay is RenderBox &&
              overlay.attached) {
            final topLeft =
                overlay.globalToLocal(source.localToGlobal(Offset.zero));
            final rect = topLeft & source.size;
            if (!rect.isEmpty && pageRect.overlaps(rect)) sourceRect = rect;
          }
          final progress = Curves.easeInOutCubic.transform(animation.value);
          if (sourceRect == null) {
            return Opacity(opacity: progress, child: child);
          }

          final rect = Rect.lerp(sourceRect, pageRect, progress)!;
          final radius = BorderRadiusGeometry.lerp(
              context.metrics.cardBorderRadius, BorderRadius.zero, progress)!;
          final surfaceOpacity = Curves.easeOut
              .transform((animation.value / 0.18).clamp(0.0, 1.0));
          final contentOpacity = Curves.easeOut
              .transform(((animation.value - 0.35) / 0.65).clamp(0.0, 1.0));
          final theme = Theme.of(context);

          return Stack(children: [
            Positioned.fromRect(
              rect: rect,
              child: Opacity(
                opacity: surfaceOpacity,
                child: DecoratedBox(
                  key: const ValueKey('report-transition-surface'),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                        theme.cardTheme.color ??
                            theme.colorScheme.surfaceContainerLow,
                        theme.scaffoldBackgroundColor,
                        progress),
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
            ClipPath(
              clipper: _CardClipper(
                  rect, radius.resolve(Directionality.of(context))),
              child: Opacity(opacity: contentOpacity, child: child),
            ),
          ]);
        },
      );
    });
  }
}

class _CardClipper extends CustomClipper<Path> {
  const _CardClipper(this.rect, this.radius);

  final Rect rect;
  final BorderRadius radius;

  @override
  Path getClip(Size size) => Path()..addRRect(radius.toRRect(rect));

  @override
  bool shouldReclip(_CardClipper oldClipper) =>
      rect != oldClipper.rect || radius != oldClipper.radius;
}
