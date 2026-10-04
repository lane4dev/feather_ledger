import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Choices that wrap on narrow screens and with longer translated labels.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips(
      {super.key,
      required this.choices,
      required this.selected,
      required this.onSelected,
      this.scrollable = false})
      : _floating = false;

  const AppChoiceChips.floating({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
  })  : scrollable = false,
        _floating = true;
  final List<ButtonSegment<T>> choices;
  final T selected;
  final ValueChanged<T>? onSelected;
  final bool scrollable;
  final bool _floating;

  @override
  Widget build(BuildContext context) {
    if (_floating) {
      return _FloatingSingleChoice<T>(
        choices: choices,
        selected: selected,
        onSelected: onSelected,
      );
    }
    final chips = [
      for (final choice in choices)
        ChoiceChip(
          label: choice.label!,
          avatar: choice.icon,
          selected: choice.value == selected,
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: onSelected == null || !choice.enabled
              ? null
              : (_) => onSelected!(choice.value),
        ),
    ];
    if (!scrollable) {
      return Wrap(
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: chips,
      );
    }
    return _AdaptiveScrollableChips(chips: chips);
  }
}

/// One shared surface and a moving selection, with equal-sized touch targets.
class _FloatingSingleChoice<T> extends StatelessWidget {
  const _FloatingSingleChoice({
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final List<ButtonSegment<T>> choices;
  final T selected;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final index = choices.indexWhere((choice) => choice.value == selected);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return IntrinsicHeight(
      child: Stack(children: [
        if (index >= 0)
          Positioned.fill(
            child: AnimatedAlign(
              duration: duration,
              curve: Curves.easeInOut,
              alignment: AlignmentDirectional(
                  choices.length == 1
                      ? 0
                      : -1 + 2 * index / (choices.length - 1),
                  0),
              child: FractionallySizedBox(
                widthFactor: 1 / choices.length,
                heightFactor: 1,
                child: DecoratedBox(
                  key: const ValueKey('floating-choice-indicator'),
                  decoration: BoxDecoration(
                    color: scheme.surfaceBright,
                    borderRadius:
                        BorderRadius.circular(context.metrics.sheetRadius),
                  ),
                ),
              ),
            ),
          ),
        Row(
          children: [
            for (final choice in choices)
              Expanded(
                child: Semantics(
                  selected: choice.value == selected,
                  inMutuallyExclusiveGroup: true,
                  button: true,
                  child: InkWell(
                    onTap: onSelected == null || !choice.enabled
                        ? null
                        : () => onSelected!(choice.value),
                    borderRadius:
                        BorderRadius.circular(context.metrics.sheetRadius),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: context.metrics.controlHeight,
                          minHeight: context.metrics.controlHeight),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: context.spacing.xs,
                            vertical: context.spacing.xs),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium!.copyWith(
                              color: choice.value == selected
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                              fontWeight: choice.value == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            child: choice.label!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

/// Measure the actual chip row, including translated text and text scaling,
/// before reserving space for scroll indicators.
class _AdaptiveScrollableChips extends StatefulWidget {
  const _AdaptiveScrollableChips({required this.chips});
  final List<Widget> chips;

  @override
  State<_AdaptiveScrollableChips> createState() =>
      _AdaptiveScrollableChipsState();
}

class _AdaptiveScrollableChipsState extends State<_AdaptiveScrollableChips> {
  final _rowKey = GlobalKey();
  bool _overflows = false;

  void _measure(double availableWidth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _rowKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final overflows = box.size.width > availableWidth + 0.5;
      if (overflows != _overflows) setState(() => _overflows = overflows);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _measure(constraints.maxWidth);
      final arrowColor = Theme.of(context).colorScheme.onSurfaceVariant;
      return Row(children: [
        if (_overflows)
          ExcludeSemantics(
              child: Icon(LucideIcons.chevronLeft,
                  size: context.metrics.iconSize, color: arrowColor)),
        Expanded(
            child: SingleChildScrollView(
          key: const ValueKey('choice-chips-scroll'),
          scrollDirection: Axis.horizontal,
          child: Row(key: _rowKey, mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < widget.chips.length; i++) ...[
              if (i > 0) SizedBox(width: context.spacing.sm),
              widget.chips[i],
            ],
          ]),
        )),
        if (_overflows)
          ExcludeSemantics(
              child: Icon(LucideIcons.chevronRight,
                  size: context.metrics.iconSize, color: arrowColor)),
      ]);
    });
  }
}
