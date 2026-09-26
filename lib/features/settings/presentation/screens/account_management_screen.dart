import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_floating_action_button_location.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/account_form_sheet.dart';
import '../widgets/account_tile.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  /// The "show every currency" sentinel, distinct from any ISO code.
  static const _allCurrencies = '__all__';

  /// The user's explicit filter. `null` means "follow the current currency",
  /// so the view tracks the setting until they override it.
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountUiListProvider);
    final current = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    final filter = _selected ?? current;
    final showCodes = filter == _allCurrencies;

    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(l10n.accountsTitle),
        actions: [
          AppIconButton(
            icon: const Icon(LucideIcons.filter),
            tooltip: l10n.filterTitle,
            onPressed: () => _openCurrencyFilter(filter),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          final visible = filter == _allCurrencies
              ? accounts
              : accounts
                  .where((account) => account.account.currencyCode == filter)
                  .toList();
          final active =
              visible.where((account) => !account.account.archived).toList();
          final archived =
              visible.where((account) => account.account.archived).toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(context.spacing.md,
                    context.spacing.md, context.spacing.md, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    showCodes
                        ? l10n.accountAllCurrencies
                        : AppCurrencies.getName(filter, l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Text(l10n.noAccountsFound))
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                            context.spacing.md,
                            context.spacing.sm,
                            context.spacing.md,
                            context.spacing.xl * 3),
                        children: [
                          for (final account in active) ...[
                            AccountTile(
                              key: ValueKey(account.account.id),
                              account: account,
                              showCurrencyCode: showCodes,
                              onTap: () => _showAccountSheet(account.account),
                            ),
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
                                    showCurrencyCode: showCodes,
                                    onTap: () =>
                                        _showAccountSheet(account.account),
                                  ),
                                  SizedBox(height: context.spacing.md),
                                ],
                              ],
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      ),
      floatingActionButtonLocation: AppFloatingActionButtonLocation(context),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAccountSheet(null),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Future<void> _openCurrencyFilter(String currentFilter) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CurrencyFilterSheet(initial: currentFilter),
    );
    if (!mounted || selected == null) return;
    final current = ref.read(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    setState(() => _selected = selected == current ? null : selected);
  }

  Future<void> _showAccountSheet(AccountEntity? account) async {
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => AccountFormSheet(account: account),
    );
    if (!mounted || created == null) return;
    final current = ref.read(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    // After creating an account in another currency, show that currency so
    // the new account is visible immediately.
    setState(() => _selected = created == current ? null : created);
  }
}

class _CurrencyFilterSheet extends StatefulWidget {
  const _CurrencyFilterSheet({required this.initial});
  final String initial;

  @override
  State<_CurrencyFilterSheet> createState() => _CurrencyFilterSheetState();
}

class _CurrencyFilterSheetState extends State<_CurrencyFilterSheet> {
  late String _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.lg, vertical: context.spacing.md),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.filterTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: context.spacing.lg),
              Text(l10n.accountCurrency,
                  style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: context.spacing.sm),
              AppChoiceChips<String>(
                choices: [
                  ButtonSegment(
                      value: _AccountManagementScreenState._allCurrencies,
                      label: Text(l10n.accountAllCurrencies)),
                  for (final code in AppCurrencies.supportedCurrencyCodes)
                    ButtonSegment(
                        value: code,
                        label: Text(AppCurrencies.getName(code, l10n))),
                ],
                selected: _draft,
                onSelected: (value) => setState(() => _draft = value),
              ),
              SizedBox(height: context.spacing.lg),
              Row(children: [
                Expanded(
                    child: AppButton.outlined(
                        onPressed: () => Navigator.pop(context,
                            _AccountManagementScreenState._allCurrencies),
                        child: Text(l10n.filterClear))),
                SizedBox(width: context.spacing.md),
                Expanded(
                    child: AppButton(
                        onPressed: () => Navigator.pop(context, _draft),
                        child: Text(l10n.filterApply))),
              ]),
            ]),
      ),
    );
  }
}
