import 'package:flutter/material.dart';
import 'ledger_sheet_handle.dart';

class LedgerSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final String Function(T) getLabel;
  final IconData? Function(T)? getIcon;
  final bool Function(T) isSelected;
  final ValueChanged<T> onSelected;

  const LedgerSelectionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.getLabel,
    required this.isSelected,
    required this.onSelected,
    this.getIcon,
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
                  final icon = getIcon?.call(option);

                  return ListTile(
                    leading: icon != null
                        ? Icon(
                            icon,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
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
                    trailing: selected
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
