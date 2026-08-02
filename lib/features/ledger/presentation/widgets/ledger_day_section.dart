import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A date in the left rail and its lazy transaction sliver share one origin.
/// The date pins below the outer app bar, but cannot leave its day's bounds.
class LedgerDaySection extends MultiChildRenderObjectWidget {
  LedgerDaySection({
    super.key,
    required Widget header,
    required Widget sliver,
    required this.headerWidth,
    this.overlapHandle,
  }) : super(children: [header, sliver]);

  final double headerWidth;
  final SliverOverlapAbsorberHandle? overlapHandle;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDaySection(
        headerWidth: headerWidth,
        overlapHandle: overlapHandle,
      );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderDaySection)
      ..headerWidth = headerWidth
      ..overlapHandle = overlapHandle;
  }
}

class _DayParentData extends ParentData
    with ContainerParentDataMixin<RenderObject> {}

class _RenderDaySection extends RenderSliver
    with ContainerRenderObjectMixin<RenderObject, _DayParentData> {
  _RenderDaySection({
    required double headerWidth,
    SliverOverlapAbsorberHandle? overlapHandle,
  })  : _headerWidth = headerWidth,
        _overlapHandle = overlapHandle;

  double _headerWidth;
  set headerWidth(double value) {
    if (_headerWidth == value) return;
    _headerWidth = value;
    markNeedsLayout();
  }

  SliverOverlapAbsorberHandle? _overlapHandle;
  set overlapHandle(SliverOverlapAbsorberHandle? value) {
    if (_overlapHandle == value) return;
    if (attached) _overlapHandle?.removeListener(markNeedsLayout);
    _overlapHandle = value;
    if (attached) _overlapHandle?.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  RenderBox get _header => firstChild! as RenderBox;
  RenderSliver get _content => lastChild! as RenderSliver;
  double _headerY = 0;
  double _pinY = 0;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _DayParentData) {
      child.parentData = _DayParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlapHandle?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _overlapHandle?.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);
    _header.layout(
      constraints.asBoxConstraints(
        crossAxisExtent: math.min(_headerWidth, constraints.crossAxisExtent),
      ),
      parentUsesSize: true,
    );
    _content.layout(constraints, parentUsesSize: true);
    final contentGeometry = _content.geometry!;
    if (contentGeometry.scrollOffsetCorrection != null) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: contentGeometry.scrollOffsetCorrection,
      );
      return;
    }

    // remainingPaintExtent locates this section within the inner viewport.
    // Read the absorber rather than hardcoding toolbar or safe-area heights;
    // its layout extent changes while the outer app bar collapses.
    final sectionY =
        constraints.viewportMainAxisExtent - constraints.remainingPaintExtent;
    _pinY = math.max(0, (_overlapHandle?.layoutExtent ?? 0) - sectionY);
    final scrollExtent =
        math.max(contentGeometry.scrollExtent, _header.size.height);
    final remaining = scrollExtent - constraints.scrollOffset;
    _headerY = math.min(_pinY, remaining - _header.size.height);
    final paintExtent = remaining.clamp(0.0, constraints.remainingPaintExtent);
    geometry = contentGeometry.copyWith(
      scrollExtent: scrollExtent,
      paintExtent: math.max(contentGeometry.paintExtent, paintExtent),
      maxPaintExtent:
          math.max(contentGeometry.maxPaintExtent, _header.size.height),
      hasVisualOverflow: true,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!geometry!.visible) return;
    if (_content.geometry!.visible) context.paintChild(_content, offset);
    // Only the date is clipped at the pin line. The transaction sliver keeps
    // its original full-width hit targets and scrolls under the app bar.
    if (_headerY + _header.size.height > _pinY) {
      context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTRB(0, _pinY, _header.size.width, geometry!.paintExtent),
        (context, offset) =>
            context.paintChild(_header, offset + Offset(0, _headerY)),
      );
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) =>
      _content.hitTest(
        result,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      );

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == _header) transform.translateByDouble(0, _headerY, 0, 1);
  }

  @override
  double childMainAxisPosition(RenderObject child) =>
      child == _header ? _headerY : 0;

  @override
  double childCrossAxisPosition(RenderObject child) => 0;

  @override
  double? childScrollOffset(RenderObject child) => child == _content ? 0 : null;
}
