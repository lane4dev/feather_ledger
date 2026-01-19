import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/database/tables.dart' as db_tables;
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/settings/data/repositories/account_repository.dart';
import 'package:feather_ledger/features/settings/presentation/providers/account_providers.dart';
import 'package:feather_ledger/features/settings/presentation/providers/settings_providers.dart';

class AccountManagementScreen extends ConsumerWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountListProvider);
    final currency = ref.watch(currencyControllerProvider).valueOrNull ?? '\$';

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
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(_getIconForAccountType(account.type)),
                ),
                title: Text(account.name),
                subtitle: Text(account.type.name.toUpperCase()),
                trailing: Text(
                    '$currency${account.initialBalance.toStringAsFixed(2)}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AccountFormScreen(account: account),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l10n.errorPrefix(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AccountFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForAccountType(db_tables.AccountType type) {
    switch (type) {
      case db_tables.AccountType.cash:
        return Icons.money;
      case db_tables.AccountType.bank:
        return Icons.account_balance;
      case db_tables.AccountType.credit:
        return Icons.credit_card;
      case db_tables.AccountType.other:
        return Icons.account_balance_wallet;
    }
  }
}

class AccountFormScreen extends ConsumerStatefulWidget {
  final AccountEntity? account;

  const AccountFormScreen({super.key, this.account});

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late db_tables.AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
        text: widget.account?.initialBalance.toString() ?? '0.0');
    _selectedType = widget.account?.type ?? db_tables.AccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.account != null;
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editAccount : l10n.addAccount),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.deleteAccountConfirmation),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref
                      .read(accountRepositoryProvider)
                      .deleteAccount(widget.account!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.accountName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.md),
              DropdownButtonFormField<db_tables.AccountType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: l10n.accountType,
                  border: const OutlineInputBorder(),
                ),
                items: db_tables.AccountType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              SizedBox(height: spacing.md),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: l10n.initialBalance,
                  border: const OutlineInputBorder(),
                  prefixText:
                      ref.watch(currencyControllerProvider).valueOrNull ?? '\$',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  if (double.tryParse(value) == null) {
                    return l10n.invalidAmount;
                  }
                  return null;
                },
              ),
              SizedBox(height: spacing.lg),
              FilledButton(
                onPressed: _save,
                child: Text(l10n
                    .saveTransaction), // Reuse 'Save Transaction' or add 'Save'
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final balance = double.parse(_balanceController.text);
      final repository = ref.read(accountRepositoryProvider);

      if (widget.account != null) {
        await repository.updateAccount(
          id: widget.account!.id,
          name: name,
          type: _selectedType,
          initialBalance: balance,
        );
      } else {
        await repository.addAccount(
          name: name,
          type: _selectedType,
          initialBalance: balance,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.accountSaved)),
        );
        Navigator.pop(context);
      }
    }
  }
}
