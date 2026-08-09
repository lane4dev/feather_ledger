import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
                                ? AppIconBadge(icon: icon, color: color)
                                : Icon(
                                    icon,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ))
                            : null),
                    title: Text(
                      getLabel(option),
                      style: (selected
                              ? AppTypography.selectedLabel(context)
                              : Theme.of(context).textTheme.bodyLarge!)
                          .copyWith(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface),
                    ),
                    trailing: getTrailing != null
                        ? getTrailing!(context, option)
                        : (selected
                            ? Icon(LucideIcons.check,
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
                padding: EdgeInsets.all(context.spacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton.outlined(
                    onPressed: () {
                      Navigator.pop(context); // Close the current sheet
                      onManageTap!(); // Execute the manage action
                    },
                    icon: const Icon(LucideIcons.settings),
                    child: Text(manageButtonText!),
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
