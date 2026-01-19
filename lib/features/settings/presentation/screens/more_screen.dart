import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';

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
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () {
              context.go('/more/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(l10n.accounts),
            onTap: () {
              context.go('/more/accounts');
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart),
            title: Text(l10n.budgets),
            onTap: () {
              // TODO: Budgets screen
            },
          ),
        ],
      ),
    );
  }
}
