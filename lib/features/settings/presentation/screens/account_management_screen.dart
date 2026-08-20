import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/account_form_sheet.dart';
import '../widgets/account_tile.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountUiListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(l10n.accountsTitle),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final active =
              accounts.where((account) => !account.account.archived).toList();
          final archived =
              accounts.where((account) => account.account.archived).toList();
          if (accounts.isEmpty)
            return Center(child: Text(l10n.noAccountsFound));
          return ListView(
            padding: EdgeInsets.fromLTRB(context.spacing.md, context.spacing.md,
                context.spacing.md, context.spacing.xl * 3),
            children: [
              for (final account in active) ...[
                AccountTile(
                    key: ValueKey(account.account.id),
                    account: account,
                    onTap: () => _showAccountSheet(context, account.account)),
                SizedBox(height: context.spacing.md),
              ],
              if (archived.isNotEmpty)
                ExpansionTile(
                  title: Text(
                      '${l10n.accountArchivedSection} (${archived.length})'),
                  children: [
                    for (final account in archived) ...[
                      AccountTile(
                          key: ValueKey(account.account.id),
                          account: account,
                          onTap: () =>
                              _showAccountSheet(context, account.account)),
                      SizedBox(height: context.spacing.md),
                    ],
                  ],
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountSheet(context, null),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, AccountEntity? account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => AccountFormSheet(account: account),
    );
  }
}
