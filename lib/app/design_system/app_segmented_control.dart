import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single-choice control with a sliding raised selection and subtle dividers.
class AppSegmentedControl<T> extends StatefulWidget {
  const AppSegmentedControl(
      {super.key,
      required this.segments,
      required this.selected,
      required this.onSelected,
      this.widthFactor,
      this.flat = false,
      this.selectionColor});

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final double? widthFactor;

  /// Drops the raised selection block for a flat tonal fill. Used by the
  /// transaction form, where the control is a segmented field rather than a
  /// floating choice.
  final bool flat;

  /// The flat selection's fill. The form passes a soft semantic tint so the
  /// kind being recorded is legible before the first character is typed.
  final Color? selectionColor;

  @override
  State<AppSegmentedControl<T>> createState() => _AppSegmentedControlState<T>();
}

class _AppSegmentedControlState<T> extends State<AppSegmentedControl<T>> {
  final _stackKey = GlobalKey();
  final _segmentKeys = <T, GlobalKey>{};
  Rect? _selectionRect;
  bool _measurementQueued = false;

  void _scheduleMeasurement() {
    if (_measurementQueued) return;
    _measurementQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementQueued = false;
      if (!mounted) return;
      final stack = _stackKey.currentContext?.findRenderObject();
      final segment =
          _segmentKeys[widget.selected]?.currentContext?.findRenderObject();
      if (stack is! RenderBox ||
          !stack.attached ||
          !stack.hasSize ||
          segment is! RenderBox ||
          !segment.attached ||
          !segment.hasSize) {
        if (_selectionRect != null) setState(() => _selectionRect = null);
        return;
      }
      final offset = segment.localToGlobal(Offset.zero, ancestor: stack);
      final rect = (offset & segment.size).deflate(context.spacing.xs);
      if (rect != _selectionRect) setState(() => _selectionRect = rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metrics = context.metrics;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    _segmentKeys.removeWhere((value, _) =>
        !widget.segments.any((segment) => segment.value == value));
    for (final segment in widget.segments) {
      _segmentKeys.putIfAbsent(segment.value, GlobalKey.new);
    }
    _scheduleMeasurement();

    Widget segment(ButtonSegment<T> option) {
      final isSelected = option.value == widget.selected;
      final content = option.icon == null || option.label == null
          ? option.label ?? option.icon ?? const SizedBox.shrink()
          : Row(mainAxisSize: MainAxisSize.min, children: [
              option.icon!,
              SizedBox(width: context.spacing.xs),
              Flexible(child: option.label!),
            ]);
      Widget button = KeyedSubtree(
        key: _segmentKeys[option.value],
        child: MergeSemantics(
          child: Semantics(
            selected: isSelected,
            inMutuallyExclusiveGroup: true,
            child: Material(
              type: MaterialType.transparency,
              child: TextButton(
                onPressed: option.enabled && !isSelected
                    ? () => widget.onSelected(option.value)
                    : option.enabled
                        ? () {}
                        : null,
                style: ButtonStyle(
                  animationDuration: duration,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.pressed)
                          ? scheme.surface.withValues(alpha: 0)
                          : null),
                  foregroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.disabled)
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : isSelected
                              ? (widget.flat
                                  ? scheme.onSurface
                                  : scheme.onSecondaryContainer)
                              : scheme.onSurfaceVariant),
                  textStyle: WidgetStatePropertyAll(theme.textTheme.bodyLarge),
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(
                      horizontal: context.spacing.lg,
                      vertical: context.spacing.sm)),
                  minimumSize: WidgetStatePropertyAll(
                      Size.square(metrics.controlHeight)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: metrics.selectionBorderRadius)),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
      if (option.tooltip != null) {
        button = Tooltip(message: option.tooltip!, child: button);
      }
      return widget.widthFactor == null
          ? Flexible(child: button)
          : Expanded(child: button);
    }

    final control = DecoratedBox(
      decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: metrics.controlBorderRadius),
      child: ClipRRect(
        borderRadius: metrics.controlBorderRadius,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.xs / 2),
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _scheduleMeasurement();
              return false;
            },
            child: SizeChangedLayoutNotifier(
              child: Stack(
                key: _stackKey,
                children: [
                  if (_selectionRect case final rect?)
                    AnimatedPositioned.fromRect(
                      rect: rect,
                      duration: duration,
                      curve: Curves.easeInOutCubic,
                      child: IgnorePointer(
                        child: Material(
                          key: const ValueKey('segment-selection'),
                          color: widget.selectionColor ??
                              scheme.secondaryContainer,
                          elevation: widget.flat ? 0 : metrics.subtleElevation,
                          shadowColor:
                              widget.flat ? Colors.transparent : scheme.shadow,
                          surfaceTintColor: scheme.surface.withValues(alpha: 0),
                          shape: RoundedRectangleBorder(
                              borderRadius: metrics.selectionBorderRadius),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < widget.segments.length; i++) ...[
                        if (i > 0)
                          SizedBox(
                            key: ValueKey('segment-divider-$i'),
                            width: 1,
                            height: metrics.controlHeight / 2,
                            child: AnimatedContainer(
                              duration: duration,
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: widget.segments[i - 1].value ==
                                            widget.selected ||
                                        widget.segments[i].value ==
                                            widget.selected
                                    ? scheme.surface.withValues(alpha: 0)
                                    : scheme.outlineVariant,
                              ),
                            ),
                          ),
                        segment(widget.segments[i]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Center(
        child: widget.widthFactor == null
            ? control
            : FractionallySizedBox(
                widthFactor: widget.widthFactor, child: control));
  }
}
