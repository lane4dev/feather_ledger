import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/database/tables.dart' as db_tables;
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/settings/data/repositories/account_repository.dart';
import 'package:feather_ledger/features/settings/presentation/providers/account_providers.dart';
import 'package:feather_ledger/features/settings/presentation/providers/settings_providers.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

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
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                  child: Icon(_getIconForAccountType(account.type)),
                ),
                title: Text(account.name),
                subtitle: Text(
                  _getAccountTypeLabel(account.type, l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  '$currency${account.initialBalance.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
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

  String _getAccountTypeLabel(
      db_tables.AccountType type, AppLocalizations l10n) {
    // Assuming generic fallback if l10n doesn't have specific keys yet,
    // or mapping to existing keys if available.
    // For now using uppercased name as in original, or better, capitalization.
    // Ideally we'd add keys to arb file, but for this refactor we stick to code.
    final name = type.name;
    return name[0].toUpperCase() + name.substring(1);
  }
}

class AccountFormSheet extends ConsumerStatefulWidget {
  final AccountEntity? account;

  const AccountFormSheet({super.key, this.account});

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _balance;
  late db_tables.AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _name = widget.account?.name ?? '';
    _balance = widget.account?.initialBalance ?? 0.0;
    _selectedType = widget.account?.type ?? db_tables.AccountType.cash;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.account != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = ref.watch(currencyControllerProvider).valueOrNull ?? '\$';

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        context.spacing.sm,
        context.spacing.lg,
        context.spacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Action Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
                tooltip: l10n.cancel,
              ),
              const Spacer(),
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  onPressed: _deleteAccount,
                  tooltip: l10n.delete,
                ),
            ],
          ),
          SizedBox(height: context.spacing.sm),

          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance Input (Hero) - Left Aligned
                    TextFormField(
                      initialValue: _balance == 0 && !isEditing
                          ? null
                          : _balance.toStringAsFixed(2),
                      textAlign: TextAlign.left,
                      decoration: InputDecoration(
                        prefixText: '$currency ',
                        prefixStyle: theme.textTheme.displaySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: '0.00',
                        hintStyle: theme.textTheme.displaySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        labelText: l10n.initialBalance,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        alignLabelWithHint: true,
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          return (text.isEmpty ||
                                  RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text))
                              ? newValue
                              : oldValue;
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return l10n.required;
                        if (double.tryParse(value) == null) {
                          return l10n.invalidAmount;
                        }
                        return null;
                      },
                      onSaved: (value) => _balance = double.parse(value!),
                    ),
                    SizedBox(height: context.spacing.lg),

                    // Account Type (SegmentedButton)
                    SegmentedButton<db_tables.AccountType>(
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.xs,
                        ),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                      segments: db_tables.AccountType.values.map((type) {
                        return ButtonSegment<db_tables.AccountType>(
                          value: type,
                          icon: Icon(
                            _getIconForAccountType(type),
                            size: 20,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              type.name[0].toUpperCase() +
                                  type.name.substring(1),
                            ),
                          ),
                        );
                      }).toList(),
                      selected: {_selectedType},
                      onSelectionChanged: (newSelection) {
                        setState(() => _selectedType = newSelection.first);
                      },
                      showSelectedIcon: false,
                    ),
                    SizedBox(height: context.spacing.lg),

                    const FeatherDivider(),
                    SizedBox(height: context.spacing.md),

                    // Name Input
                    _FormRow(
                      icon: Icons.label_outline,
                      child: TextFormField(
                        initialValue: _name,
                        decoration: InputDecoration(
                          hintText: l10n.accountName,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          isDense: true,
                        ),
                        style: theme.textTheme.bodyLarge,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => (value == null || value.isEmpty)
                            ? l10n.required
                            : null,
                        onSaved: (value) => _name = value!,
                      ),
                    ),

                    SizedBox(height: context.spacing.xl),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        child: Text(l10n.saveTransaction),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await ref
          .read(accountRepositoryProvider)
          .deleteAccount(widget.account!.id);
      if (mounted) context.pop();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final repository = ref.read(accountRepositoryProvider);

      try {
        if (widget.account != null) {
          await repository.updateAccount(
            id: widget.account!.id,
            name: _name,
            type: _selectedType,
            initialBalance: _balance,
          );
        } else {
          await repository.addAccount(
            name: _name,
            type: _selectedType,
            initialBalance: _balance,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.accountSaved),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _FormRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _FormRow({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, right: 24.0),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
