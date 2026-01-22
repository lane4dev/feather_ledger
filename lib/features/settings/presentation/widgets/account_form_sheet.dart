import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart'; // Added import
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart'; // Point to shared extension

import '../providers/settings_providers.dart';

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
  late AccountType _selectedType; // Removed prefix

  @override
  void initState() {
    super.initState();
    _name = widget.account?.name ?? '';
    _balance = widget.account?.initialBalance ?? 0.0;
    _selectedType = widget.account?.type ?? AccountType.cash; // Removed prefix
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
                        if (value == null || value.isEmpty) {
                          return l10n.required;
                        }
                        if (double.tryParse(value) == null) {
                          return l10n.invalidAmount;
                        }
                        return null;
                      },
                      onSaved: (value) => _balance = double.parse(value!),
                    ),
                    SizedBox(height: context.spacing.lg),

                    // Account Type (SegmentedButton)
                    SegmentedButton<AccountType>(
                      // Removed prefix
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.xs,
                        ),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                      segments: AccountType.values.map((type) {
                        // Removed prefix
                        return ButtonSegment<AccountType>(
                          // Removed prefix
                          value: type,
                          icon: Icon(
                            type.icon,
                            size: 20,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              type.localizedLabel(context),
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
