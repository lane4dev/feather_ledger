import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';

import '../widgets/account_form_sheet.dart';
import '../widgets/account_tile.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountListProvider);
    final currencyKey =
        ref.watch(currencyControllerProvider).valueOrNull ?? '\$';
    final currency = AppCurrencies.getSymbol(currencyKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(child: Text(l10n.noAccountsFound));
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return AccountTile(
                account: account,
                currencySymbol: currency,
                onTap: () => _showAccountSheet(context, account),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountSheet(context, null),
        child: const Icon(Icons.add),
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
