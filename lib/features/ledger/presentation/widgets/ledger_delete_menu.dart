import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The overflow menu at the top right of a ledger bottom sheet, holding the
/// one destructive action a sheet offers.
///
/// It is a widget rather than a copy because the sheets must agree: a
/// transaction and a pending bill delete through the same gesture, in the
/// same corner, in the same colour. Two hand-rolled menus is how they stop
/// agreeing.
class LedgerDeleteMenu extends StatelessWidget {
  const LedgerDeleteMenu({super.key, required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = Theme.of(context).colorScheme.error;

    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.ellipsisVertical),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, color: error, size: 20),
              SizedBox(width: context.spacing.sm),
              Text(l10n.delete,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: error)),
            ],
          ),
        ),
      ],
    );
  }
}
