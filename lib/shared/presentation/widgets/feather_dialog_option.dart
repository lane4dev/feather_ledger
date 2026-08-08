import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One choice in a menu dialog — a [SimpleDialog] full of these.
///
/// A menu, not a form: tapping an option *is* the answer. [onChanged] is where
/// the caller commits and closes, so the dialog carries no confirm button:
/// there is nothing left to confirm.
///
/// The option in force is marked twice — weight and the accent colour on the
/// label, plus a check mark — because the list is often longer than the eye
/// takes in at once, and "which one am I on" is the question the dialog is
/// open to answer.
class FeatherDialogOption<T> extends StatelessWidget {
  final String label;
  final T value;

  /// The option currently in force, marked as such.
  final T? groupValue;

  final ValueChanged<T> onChanged;

  const FeatherDialogOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = value == groupValue;

    return SimpleDialogOption(
      onPressed: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: (isSelected
                        ? AppTypography.selectedLabel(context)
                        : Theme.of(context).textTheme.bodyLarge!)
                    .copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface),
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.check, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
