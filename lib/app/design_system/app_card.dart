import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../theme/account_card_theme.dart';
import '../theme/app_theme.dart';

enum _AppCardVariant { standard, outlined, group, overview, day, account }

/// M3 surface entry point for feature UI. Shape, elevation and colours are
/// read from ThemeData, so callers do not create local visual systems.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AccountType? _accountType;
  final bool _archived;
  final VoidCallback? _onTap;
  final _AppCardVariant _variant;

  const AppCard(
      {super.key, required this.child, this.padding, VoidCallback? onTap})
      : _accountType = null,
        _archived = false,
        _onTap = onTap,
        _variant = _AppCardVariant.standard;

  const AppCard.outlined({super.key, required this.child, this.padding})
      : _accountType = null,
        _archived = false,
        _onTap = null,
        _variant = _AppCardVariant.outlined;

  const AppCard.group({super.key, required this.child})
      : padding = EdgeInsets.zero,
        _accountType = null,
        _archived = false,
        _onTap = null,
        _variant = _AppCardVariant.group;

  /// Elevated-tonal overview surface (`surfaceContainerHigh` + 24dp radius).
  const AppCard.overview(
      {super.key, required this.child, this.padding, VoidCallback? onTap})
      : _accountType = null,
        _archived = false,
        _onTap = onTap,
        _variant = _AppCardVariant.overview;

  /// Daily transaction group surface (`surfaceContainerLow` + 18dp radius).
  const AppCard.day(
      {super.key, required this.child, this.padding, VoidCallback? onTap})
      : _accountType = null,
        _archived = false,
        _onTap = onTap,
        _variant = _AppCardVariant.day;

  /// A subdued financial surface. Decoration and touch feedback share the
  /// same clipped Material, so the texture never covers the ripple or text.
  const AppCard.account({
    super.key,
    required this.child,
    required AccountType type,
    bool archived = false,
    VoidCallback? onTap,
    this.padding,
  })  : _accountType = type,
        _archived = archived,
        _onTap = onTap,
        _variant = _AppCardVariant.account;

  @override
  Widget build(BuildContext context) {
    final content =
        Padding(padding: padding ?? context.metrics.cardPadding, child: child);
    final type = _accountType;
    if (_variant != _AppCardVariant.account || type == null) {
      final scheme = Theme.of(context).colorScheme;
      final metrics = context.metrics;
      final color = switch (_variant) {
        _AppCardVariant.outlined => scheme.surface,
        _AppCardVariant.overview => scheme.surfaceContainerHigh,
        _AppCardVariant.day => scheme.surfaceContainerLow,
        _ => null,
      };
      final borderRadius = switch (_variant) {
        _AppCardVariant.overview => metrics.overviewCardBorderRadius,
        _AppCardVariant.day => metrics.dayCardBorderRadius,
        _ => metrics.cardBorderRadius,
      };
      final ShapeBorder? shape = switch (_variant) {
        _AppCardVariant.outlined => RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: scheme.outlineVariant),
          ),
        _AppCardVariant.overview ||
        _AppCardVariant.day =>
          RoundedRectangleBorder(borderRadius: borderRadius),
        _ => null,
      };

      return Card(
        color: color,
        surfaceTintColor: color,
        shape: shape,
        child: _onTap != null
            ? InkWell(
                onTap: _onTap,
                borderRadius: borderRadius,
                child: content,
              )
            : _variant == _AppCardVariant.group
                ? ListTileTheme(
                    data: ListTileTheme.of(context)
                        .copyWith(contentPadding: metrics.fieldPadding),
                    child: content,
                  )
                : content,
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AccountCardTheme>()!;
    final accent = tokens.accent(type, scheme, archived: _archived);
    final dark = theme.brightness == Brightness.dark;
    final tint = _archived
        ? 0.02
        : dark
            ? 0.08
            : 0.055;
    final radius = context.metrics.cardBorderRadius;

    return Card(
      margin: EdgeInsets.zero,
      elevation: context.metrics.subtleElevation,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: scheme.surfaceContainerLow,
      shadowColor: scheme.shadow.withValues(alpha: dark ? 0.18 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(scheme.surfaceContainerLow, accent, tint / 3)!,
              Color.lerp(scheme.surfaceContainerLow, accent, tint)!,
            ],
          ),
        ),
        child: InkWell(
          onTap: _onTap,
          borderRadius: radius,
          child: CustomPaint(
            painter: _AccountArcPainter(accent),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _AccountArcPainter extends CustomPainter {
  const _AccountArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width + size.height * 0.12, -size.height * 0.3);
    canvas.drawCircle(centre, size.height * 1.05,
        Paint()..color = color.withValues(alpha: 0.025));
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final scale in [0.66, 0.86, 1.06]) {
      canvas.drawCircle(centre, size.height * scale, stroke);
    }
  }

  @override
  bool shouldRepaint(_AccountArcPainter oldDelegate) =>
      color != oldDelegate.color;
}
