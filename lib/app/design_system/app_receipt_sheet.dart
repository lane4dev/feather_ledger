import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_sheet_handle.dart';

/// Shared route configuration for receipts, keeping their outer margins clear.
Future<T?> showAppReceiptSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
  );
}

/// Presentation only: neither history queries nor ledger actions belong here.
class AppReceiptSheet extends StatelessWidget {
  const AppReceiptSheet(
      {super.key, required this.toolbar, required this.child, this.footer});
  final Widget toolbar;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tearY = context.spacing.xl * 2.75;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          context.spacing.md, 0, context.spacing.md, context.spacing.sm),
      child: PhysicalShape(
        clipper: _ReceiptClipper(
          topRadius: context.spacing.xl,
          notchRadius: context.spacing.sm,
          tearY: tearY,
          scallopRadius: context.spacing.xs,
        ),
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
        elevation: context.spacing.sm,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: tearY,
              child: Column(children: [
                const AppSheetHandle(),
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                  child: toolbar,
                )),
              ]),
            ),
            _Perforation(color: theme.colorScheme.outlineVariant),
            Flexible(
                child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  context.spacing.xl,
                  context.spacing.xl,
                  context.spacing.xl,
                  footer == null
                      ? context.spacing.xl + context.spacing.md
                      : context.spacing.lg),
              child: child,
            )),
            if (footer != null) footer!,
          ]),
        ),
      ),
    );
  }
}

class AppReceiptRow extends StatelessWidget {
  const AppReceiptRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: context.spacing.xl * 2,
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
            Expanded(child: Text(value, style: AppTypography.amount(context))),
          ]),
        ),
        const AppReceiptDivider(),
      ]);
}

class _Perforation extends StatelessWidget {
  const _Perforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.spacing.xs,
      width: double.infinity,
      child: CustomPaint(
        painter: _DottedLinePainter(
          color: color,
          radius: context.spacing.xs / 2,
          gap: context.spacing.sm,
        ),
      ),
    );
  }
}

class AppReceiptDivider extends StatelessWidget {
  const AppReceiptDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: Theme.of(context).colorScheme.outlineVariant,
          dash: context.spacing.sm,
          gap: context.spacing.xs,
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({
    required this.color,
    required this.radius,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = radius; x < size.width; x += radius * 2 + gap) {
      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      gap != oldDelegate.gap;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dash).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      dash != oldDelegate.dash ||
      gap != oldDelegate.gap;
}

class _ReceiptClipper extends CustomClipper<Path> {
  const _ReceiptClipper({
    required this.topRadius,
    required this.notchRadius,
    required this.tearY,
    required this.scallopRadius,
  });

  final double topRadius;
  final double notchRadius;
  final double tearY;
  final double scallopRadius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(topRadius, 0)
      ..lineTo(size.width - topRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, topRadius)
      ..lineTo(size.width, tearY - notchRadius)
      ..quadraticBezierTo(
        size.width - notchRadius,
        tearY - notchRadius,
        size.width - notchRadius,
        tearY,
      )
      ..quadraticBezierTo(
        size.width - notchRadius,
        tearY + notchRadius,
        size.width,
        tearY + notchRadius,
      )
      ..lineTo(size.width, size.height - scallopRadius * 2);

    var x = size.width;
    while (x > scallopRadius * 2) {
      path
        ..quadraticBezierTo(
          x - scallopRadius,
          size.height - scallopRadius * 2,
          x - scallopRadius,
          size.height - scallopRadius,
        )
        ..quadraticBezierTo(
          x - scallopRadius,
          size.height,
          x - scallopRadius * 2,
          size.height,
        );
      x -= scallopRadius * 2;
    }

    path
      ..lineTo(0, size.height)
      ..lineTo(0, tearY + notchRadius)
      ..quadraticBezierTo(
        notchRadius,
        tearY + notchRadius,
        notchRadius,
        tearY,
      )
      ..quadraticBezierTo(
        notchRadius,
        tearY - notchRadius,
        0,
        tearY - notchRadius,
      )
      ..lineTo(0, topRadius)
      ..quadraticBezierTo(0, 0, topRadius, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_ReceiptClipper oldClipper) =>
      topRadius != oldClipper.topRadius ||
      notchRadius != oldClipper.notchRadius ||
      tearY != oldClipper.tearY ||
      scallopRadius != oldClipper.scallopRadius;
}

/// A scannable Code 128 barcode generated from the transaction date and the
/// time at which its recorded event occurred.
