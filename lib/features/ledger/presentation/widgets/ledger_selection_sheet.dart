import 'package:flutter/material.dart';
import 'ledger_sheet_handle.dart';

class LedgerSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final String Function(T) getLabel;
  final bool Function(T) isSelected;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext context, T option)? getTrailing;
  final IconData? Function(T)? getIcon;
  final Color? Function(T)? getColor;
  final Widget Function(BuildContext context, T option)? getLeading;
  final VoidCallback? onManageTap;
  final String? manageButtonText;

  const LedgerSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.getLabel,
    required this.isSelected,
    required this.onSelected,
    this.getTrailing,
    this.getIcon,
    this.getColor,
    this.getLeading,
    this.onManageTap,
    this.manageButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const LedgerSheetHandle(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = isSelected(option);
                  final leading = getLeading?.call(context, option);
                  final icon = getIcon?.call(option);
                  final color = getColor?.call(option);

                  return ListTile(
                    leading: leading ??
                        (icon != null
                            ? (color != null
                                ? CircleAvatar(
                                    backgroundColor: color.withAlpha(
                                        50), // Using withAlpha for consistency
                                    foregroundColor: color,
                                    child: Icon(icon, size: 20),
                                  )
                                : Icon(
                                    icon,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ))
                            : null),
                    title: Text(
                      getLabel(option),
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: getTrailing != null
                        ? getTrailing!(context, option)
                        : (selected
                            ? Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary)
                            : null),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
            if (onManageTap != null && manageButtonText != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close the current sheet
                      onManageTap!(); // Execute the manage action
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(manageButtonText!),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
