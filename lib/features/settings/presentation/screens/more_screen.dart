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
            subtitle: Text(l10n.settingsHint),
            trailing: const Icon(LucideIcons.chevronRight),
            // Pushed, not gone to: each of these is a page of its own, opened
            // over the shell so the bottom bar does not follow it in — the
            // route carries the parent navigator key that makes that happen.
            onTap: () => context.push('/more/settings'),
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(LucideIcons.wallet),
            title: Text(l10n.accounts),
            subtitle: Text(l10n.accountsHint),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => context.push('/accounts_management'),
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(LucideIcons.shapes),
            title: Text(l10n.categories),
            subtitle: Text(l10n.categoriesHint),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => context.push('/categories_management'),
          ),
          const FeatherDivider(),

          SizedBox(height: spacing.md),

          // Support & Info
          ListTile(
            leading: const Icon(LucideIcons.messageSquare),
            title: Text(l10n.feedback),
            subtitle: Text(l10n.feedbackHint),
            trailing: const Icon(LucideIcons.chevronRight),
            // The only entry with no page behind it yet, so it says so
            // rather than pushing an empty screen.
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
            subtitle: Text(l10n.aboutHint),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: () => context.push('/more/about'),
          ),
        ],
      ),
    );
  }
}
