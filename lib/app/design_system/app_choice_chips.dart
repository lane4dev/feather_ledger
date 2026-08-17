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
      this.scrollable = false});
  final List<ButtonSegment<T>> choices;
  final T selected;
  final ValueChanged<T>? onSelected;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
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
