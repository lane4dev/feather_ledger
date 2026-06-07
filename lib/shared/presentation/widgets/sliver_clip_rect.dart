// shared/presentation/widgets/sliver_clip_rect.dart

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverClipRect extends SingleChildRenderObjectWidget {
  const SliverClipRect({
    super.key,
    required Widget sliver,
    this.clipBehavior = Clip.hardEdge,
  }) : super(child: sliver);

  final Clip clipBehavior;

  @override
  RenderSliverClipRect createRenderObject(BuildContext context) {
    return RenderSliverClipRect(
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverClipRect renderObject,
  ) {
    renderObject.clipBehavior = clipBehavior;
  }
}

class RenderSliverClipRect extends RenderProxySliver {
  RenderSliverClipRect({
    Clip clipBehavior = Clip.hardEdge,
  }) : _clipBehavior = clipBehavior;

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;

  set clipBehavior(Clip value) {
    if (value == _clipBehavior) return;
    _clipBehavior = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || geometry == null) {
      return;
    }

    if (geometry!.paintExtent <= 0.0) {
      return;
    }

    final Rect clipRect = switch (constraints.axis) {
      Axis.vertical => Rect.fromLTWH(
          0,
          0,
          constraints.crossAxisExtent,
          geometry!.paintExtent,
        ),
      Axis.horizontal => Rect.fromLTWH(
          0,
          0,
          geometry!.paintExtent,
          constraints.crossAxisExtent,
        ),
    };

    context.pushClipRect(
      needsCompositing,
      offset,
      clipRect,
      (PaintingContext context, Offset offset) {
        super.paint(context, offset);
      },
      clipBehavior: _clipBehavior,
    );
  }
}
