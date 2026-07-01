import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

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
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/more/settings');
            },
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(l10n.accounts),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/more/accounts');
            },
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(Icons.category),
            title: Text(l10n.categories),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/more/categories');
            },
          ),
          const FeatherDivider(),

          SizedBox(height: spacing.md),

          // Support & Info
          ListTile(
            leading: const Icon(Icons.feedback),
            title: Text(l10n.feedback),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureNotAvailable)),
              );
            },
          ),
          const FeatherDivider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/more/about');
            },
          ),
        ],
      ),
    );
  }
}
