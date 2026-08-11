import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/design_system/app_form_row.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/settings/domain/services/account_service.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:uuid/uuid.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AccountFormSheet extends ConsumerStatefulWidget {
  final AccountEntity? account;

  const AccountFormSheet({super.key, this.account});

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _balanceMinor;
  late AccountType _selectedType; // Removed prefix
  late bool _includeInTotals;

  @override
  void initState() {
    super.initState();
    _name = widget.account?.name ?? '';
    _balanceMinor = widget.account?.balanceMinor ?? 0;
    _selectedType = widget.account?.type ?? AccountType.cash; // Removed prefix
    // New accounts count unless the user says otherwise; the entity already
    // answers `true` for one that predates the flag.
    _includeInTotals = widget.account?.includeInTotals ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.account != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyKey = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    final currency = AppCurrencies.getSymbol(currencyKey);

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
          const AppSheetHandle(),

          // Action Bar
          Row(
            children: [
              AppIconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => context.pop(),
                tooltip: l10n.cancel,
              ),
              const Spacer(),
              if (isEditing)
                AppIconButton.destructive(
                  icon: const Icon(LucideIcons.trash2),
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
                    // Name first: an account is what it is called before it
                    // is what it holds.
                    _FormRow(
                      icon: LucideIcons.tag,
                      child: AppTextField(
                        initialValue: _name,
                        variant: AppFieldVariant.inline,
                        hintText: l10n.accountName,
                        style: theme.textTheme.bodyLarge,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => (value == null || value.isEmpty)
                            ? l10n.required
                            : null,
                        onSaved: (value) => _name = value!,
                      ),
                    ),
                    SizedBox(height: context.spacing.md),

                    // Account Type (SegmentedButton)
                    AppChoiceChips<AccountType>(
                      choices: [
                        for (final type in AccountType.values)
                          ButtonSegment(
                              value: type,
                              icon: Icon(type.icon),
                              label: Text(type.localizedLabel(context)))
                      ],
                      selected: _selectedType,
                      onSelected: isEditing
                          ? null
                          : (type) => setState(() => _selectedType = type),
                    ),
                    SizedBox(height: context.spacing.lg),

                    const FeatherDivider(),
                    SizedBox(height: context.spacing.md),

                    // Balance Input (Hero) - Left Aligned
                    AppTextField(
                      // The same input boundary as the ledger's amount
                      // field: seeded with the decimal text, read back with
                      // [parseMinor].
                      initialValue: _balanceMinor == 0 && !isEditing
                          ? null
                          : formatMinor(_balanceMinor),
                      textAlign: TextAlign.left,
                      variant: AppFieldVariant.amount,
                      hintText: '0.00',
                      labelText: l10n.initialBalance,
                      prefixText: '$currency ',
                      floatingLabel: true,
                      style: AppTypography.amountInput(context)
                          .copyWith(color: colorScheme.primary),
                      // A balance is signed — a credit card starts in debt —
                      // so this field takes the minus, and its keypad has one.
                      // Without that, a negative seeded into it (an existing
                      // account being edited) could be shown but never
                      // re-typed: the formatter would revert every edit that
                      // kept the sign.
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = newValue.text;
                          return (text.isEmpty ||
                                  RegExp(r'^-?\d*\.?\d{0,2}$').hasMatch(text))
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
                      onSaved: (value) => _balanceMinor = parseMinor(value!),
                    ),

                    SizedBox(height: context.spacing.sm),

                    // Out of the ledger totals, not out of the ledger: the
                    // account stays everywhere it is shown, and only stops
                    // counting in the sums. See CONTEXT.md.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.accountIncludeInTotals),
                      subtitle: Text(l10n.accountIncludeInTotalsHint),
                      value: _includeInTotals,
                      onChanged: (value) =>
                          setState(() => _includeInTotals = value),
                    ),

                    SizedBox(height: context.spacing.lg),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        onPressed: _save,
                        child: Text(l10n.save),
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
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton.text(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await ref.read(accountServiceProvider).archiveAccount(
            commandId: const Uuid().v4(),
            accountId: widget.account!.id,
          );
      if (mounted) context.pop();
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final service = ref.read(accountServiceProvider);

      Result<void> result;
      if (widget.account != null) {
        final currentBalanceMinor = widget.account!.balanceMinor;
        final balanceChanged = _balanceMinor != currentBalanceMinor;
        if (balanceChanged) {
          final l10n = AppLocalizations.of(context)!;
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.balanceChangeDetectedTitle),
              content: Text(l10n.balanceChangeDetectedMessage),
              actions: [
                AppButton.text(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                AppButton.text(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.save),
                ),
              ],
            ),
          );

          if (confirm != true) return;
        }

        result = await service.renameAccount(
          commandId: const Uuid().v4(),
          accountId: widget.account!.id,
          name: _name,
        );

        if (balanceChanged && result is Success<void>) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context)!;
          result = await service.adjustAccountBalance(
            commandId: const Uuid().v4(),
            accountId: widget.account!.id,
            newBalanceMinor: _balanceMinor,
            description: l10n.accountBalanceAdjustmentDescription,
            notes: l10n.accountBalanceAdjustmentNotes,
          );
        }

        // Its own event, and its own commandId: nothing about the money moved,
        // so it does not belong inside either write above.
        if (_includeInTotals != widget.account!.includeInTotals &&
            result is Success<void>) {
          result = await service.setTotalsInclusion(
            commandId: const Uuid().v4(),
            accountId: widget.account!.id,
            includeInTotals: _includeInTotals,
          );
        }
      } else {
        final currencyKey = ref.read(currencyControllerProvider).value ??
            AppCurrencies.defaultCurrency.code;
        final l10n = AppLocalizations.of(context)!;
        result = await service.createAccount(
          commandId: const Uuid().v4(),
          name: _name,
          type: _selectedType,
          initialBalanceMinor: _balanceMinor,
          currencyCode: currencyKey,
          // A new account's whole balance is the difference from nothing, and
          // the row says so rather than looking like income.
          initialBalanceNote: l10n.accountInitialBalanceNote,
          includeInTotals: _includeInTotals,
        );
      }

      if (result case Failure(:final code)) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(code.message(l10n))),
          );
        }
        return;
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
    }
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.icon, required this.child});
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => AppFormRow(icon: icon, child: child);
}
