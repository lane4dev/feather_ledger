import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: spacing.sm),
        children: [
          // Configuration & Management
          ListTile(
            leading: const Icon(LucideIcons.settings),
            title: Text(l10n.settings),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              context.go('/more/settings');
            },
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(LucideIcons.wallet),
            title: Text(l10n.accounts),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              context.go('/more/accounts');
            },
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(LucideIcons.shapes),
            title: Text(l10n.categories),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              context.go('/more/categories');
            },
          ),
          const FeatherDivider(),

          SizedBox(height: spacing.md),

          // Support & Info
          ListTile(
            leading: const Icon(LucideIcons.messageSquare),
            title: Text(l10n.feedback),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureNotAvailable)),
              );
            },
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(LucideIcons.info),
            title: Text(l10n.about),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () {
              context.go('/more/about');
            },
          ),
        ],
      ),
    );
  }
}
