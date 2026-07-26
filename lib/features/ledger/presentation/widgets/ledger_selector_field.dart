import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LedgerSelectorField extends StatelessWidget {
  /// A persistent field name. When provided, [text] is rendered as the
  /// current value rather than replacing the field's meaning.
  final String? label;
  final String text;
  final TextStyle? textStyle;
  final VoidCallback onTap;
  final String? errorText;

  const LedgerSelectorField({
    super.key,
    this.label,
    required this.text,
    this.textStyle,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final value = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: label == null ? null : TextAlign.end,
      style: textStyle ?? theme.textTheme.bodyLarge,
    );

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                // Without a label the value stands in for the field's name, so
                // it keeps the leading edge and the spacer sits between it and
                // the chevron. The unlabelled callers (the recurring bill form,
                // the filter sheet) relied on that, and a spacer *before* it
                // parks the value in the middle of the row instead.
                if (label != null) ...[
                  Expanded(
                    child: Text(label!, style: theme.textTheme.bodyLarge),
                  ),
                  const SizedBox(width: 16),
                  Flexible(child: value),
                ] else ...[
                  value,
                  const Spacer(),
                ],
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, color: theme.hintColor),
              ],
            ),
          ),
          if (errorText != null)
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
