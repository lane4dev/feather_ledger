import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The square viewport shows exactly the pixels returned by this dialog.
class CategoryIconCropDialog extends StatefulWidget {
  const CategoryIconCropDialog({super.key, required this.image});
  final ui.Image image;

  @override
  State<CategoryIconCropDialog> createState() => _CategoryIconCropDialogState();
}

class _CategoryIconCropDialogState extends State<CategoryIconCropDialog> {
  static const _maxZoom = 4.0;
  late final ui.Image _image;
  late Offset _center;
  double _zoom = 1;
  double _startZoom = 1;
  Offset _startImagePoint = Offset.zero;

  double get _shortSide => math.min(_image.width, _image.height).toDouble();
  double get _cropSide => _shortSide / _zoom;

  @override
  void initState() {
    super.initState();
    _image = widget.image.clone();
    _center = Offset(_image.width / 2, _image.height / 2);
  }

  @override
  void dispose() {
    _image.dispose();
    super.dispose();
  }

  void _setCrop(double zoom, Offset center) {
    _zoom = zoom.clamp(1, _maxZoom);
    final half = _cropSide / 2;
    _center = Offset(
      center.dx.clamp(half, _image.width - half),
      center.dy.clamp(half, _image.height - half),
    );
  }

  Rect get _crop =>
      Rect.fromCenter(center: _center, width: _cropSide, height: _cropSide);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.cropCategoryIcon),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 280,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(builder: (context, constraints) {
                final size = constraints.maxWidth;
                final scale = size / _cropSide;
                return GestureDetector(
                  key: const ValueKey('category-icon-crop-viewport'),
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _startZoom = _zoom;
                    _startImagePoint = _center +
                        (details.localFocalPoint - Offset(size / 2, size / 2)) /
                            scale;
                  },
                  onScaleUpdate: (details) {
                    final zoom =
                        (_startZoom * details.scale).clamp(1.0, _maxZoom);
                    final nextScale = size * zoom / _shortSide;
                    setState(() => _setCrop(
                        zoom,
                        _startImagePoint -
                            (details.localFocalPoint -
                                    Offset(size / 2, size / 2)) /
                                nextScale));
                  },
                  child: ClipRect(
                    child: Stack(clipBehavior: Clip.hardEdge, children: [
                      Positioned(
                        left: size / 2 - _center.dx * scale,
                        top: size / 2 - _center.dy * scale,
                        width: _image.width * scale,
                        height: _image.height * scale,
                        child: RawImage(image: _image, fit: BoxFit.fill),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CropGridPainter(
                              light: Theme.of(context).colorScheme.surface,
                              dark: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                          child: IgnorePointer(
                              child: DecoratedBox(
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 2)),
                      ))),
                    ]),
                  ),
                );
              }),
            ),
            SizedBox(height: context.spacing.md),
            Text(l10n.categoryIconCropDescription),
            Row(children: [
              const Icon(LucideIcons.zoomOut),
              Expanded(
                  child: Slider(
                value: _zoom,
                min: 1,
                max: _maxZoom,
                label: l10n.categoryIconZoom,
                onChanged: (value) => setState(() => _setCrop(value, _center)),
              )),
              const Icon(LucideIcons.zoomIn),
            ]),
          ]),
        ),
      ),
      actions: [
        AppButton.text(
            onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        AppButton.text(
            onPressed: () => Navigator.pop(context, _crop),
            child: Text(l10n.save)),
      ],
    );
  }
}

class _CropGridPainter extends CustomPainter {
  const _CropGridPainter({required this.light, required this.dark});

  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    final contrast = Paint()
      ..color = dark.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    final line = Paint()
      ..color = light.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      for (final paint in [contrast, line]) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CropGridPainter oldDelegate) =>
      oldDelegate.light != light || oldDelegate.dark != dark;
}
