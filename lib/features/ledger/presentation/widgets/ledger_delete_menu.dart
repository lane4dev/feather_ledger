import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// An action item rendered in [LedgerDeleteMenu]'s overflow popup.
class LedgerOverflowAction {
  const LedgerOverflowAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// The overflow menu at the top right of a ledger bottom sheet, holding the
/// destructive (and bill-lifecycle) actions a sheet offers.
///
/// It is a widget rather than a copy because the sheets must agree: a
/// transaction and a pending bill act through the same gesture, in the
/// same corner, in the same colour. Two hand-rolled menus is how they stop
/// agreeing.
class LedgerDeleteMenu extends StatelessWidget {
  const LedgerDeleteMenu({super.key, this.onDelete, this.actions});

  final VoidCallback? onDelete;
  final List<LedgerOverflowAction>? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final items = actions ??
        [
          LedgerOverflowAction(
            label: l10n.delete,
            icon: LucideIcons.trash2,
            onSelected: () => onDelete?.call(),
            destructive: true,
          ),
        ];

    return PopupMenuButton<int>(
      icon: const Icon(LucideIcons.ellipsisVertical),
      onSelected: (index) => items[index].onSelected(),
      itemBuilder: (context) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem(
            value: i,
            child: Row(
              children: [
                Icon(
                  items[i].icon,
                  color: items[i].destructive
                      ? error
                      : theme.colorScheme.onSurface,
                  size: 20,
                ),
                SizedBox(width: context.spacing.sm),
                Text(
                  items[i].label,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: items[i].destructive
                        ? error
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
