import 'package:flutter/material.dart';

class LedgerSelectorField extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final VoidCallback onTap;
  final String? errorText;

  const LedgerSelectorField({
    super.key,
    required this.text,
    this.textStyle,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  text,
                  style: textStyle ?? theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: theme.hintColor),
              ],
            ),
          ),
          if (errorText != null)
            Text(
              errorText!,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
