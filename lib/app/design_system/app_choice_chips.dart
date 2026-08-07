import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Choices that wrap on narrow screens and with longer translated labels.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips(
      {super.key,
      required this.choices,
      required this.selected,
      required this.onSelected});
  final List<ButtonSegment<T>> choices;
  final T selected;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: [
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
        ],
      );
}
