import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
import '../widgets/ledger_selection_sheet.dart';
import '../widgets/ledger_selector_field.dart';

/// Records or corrects a transfer (spec 004, US1).
///
/// A transfer has no category and two accounts, so it gets its own screen
/// rather than a third segment on the income/expense form — that form would
/// otherwise have to represent states a transfer cannot have (a category, or
/// a single account). `null` means create, non-null means correct.
class TransferFormScreen extends ConsumerStatefulWidget {
  final TransactionTileUiModel? transaction;

  const TransferFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransferFormScreen> createState() =>
      _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _amountMinor;
  DateTime _date = DateTime.now();
  String? _note;
  String? _fromAccountId;
  String? _toAccountId;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;
    if (transaction != null) {
      _amountMinor = transaction.amount;
      _date = transaction.date;
      _note = transaction.note;
      _fromAccountId = transaction.account.id;
      _toAccountId = transaction.toAccount?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.transaction == null
            ? l10n.addTransfer
            : l10n.editTransfer),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.lg, vertical: context.spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              accountsAsync.when(
                data: (accounts) {
                  // Archived accounts are not offered (spec 003, US3); their
                  // history and balances stay.
                  final active =
                      accounts.where((a) => !a.archived).toList();
                  final from = _resolve(active, _fromAccountId);

                  // Same currency is an aggregate invariant, so the options
                  // are narrowed to make the illegal pair unreachable rather
                  // than letting the user pick it and rejecting on save
                  // (ADR-0002's "unrepresentable, not written-then-rejected").
                  final toOptions = active
                      .where((a) => a.id != _fromAccountId)
                      .where((a) => from == null ||
                          a.currencyCode == from.currencyCode)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LedgerAmountInput(
                        initialMinorUnits: _amountMinor,
                        type: TransactionKind.transfer,
                        // The "from" account's own currency once chosen; the
                        // app default until then.
                        currencySymbol: AppCurrencies.getSymbol(
                            from?.currencyCode ??
                                AppCurrencies.defaultCurrency.code),
                        autofocus: widget.transaction == null,
                        onSaved: (minor) => _amountMinor = minor,
                      ),
                      const SizedBox(height: 32),
                      const FeatherDivider(),
                      const SizedBox(height: 16),

                      _accountRow(
                        fieldKey: const ValueKey('transfer-from'),
                        icon: Icons.arrow_upward,
                        title: l10n.transferFrom,
                        options: active,
                        selectedId: _fromAccountId,
                        l10n: l10n,
                        onSelected: (id) => setState(() {
                          _fromAccountId = id;
                          // The "to" field is keyed on the from-account, so
                          // re-keying resets a choice that the new currency
                          // filter may no longer allow.
                          _toAccountId = null;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _accountRow(
                        // Re-keying on the from-account resets this field
                        // whenever the eligible options change.
                        fieldKey: ValueKey('transfer-to-$_fromAccountId'),
                        icon: Icons.arrow_downward,
                        title: l10n.transferTo,
                        options: toOptions,
                        selectedId: _toAccountId,
                        l10n: l10n,
                        onSelected: (id) =>
                            setState(() => _toAccountId = id),
                        // Defence in depth: the options above already exclude
                        // it, but Transaction.validate is the real guard and
                        // this keeps an unreachable state from becoming
                        // reachable through a future refactor.
                        validator: (value) =>
                            value != null && value == _fromAccountId
                                ? l10n.errorSameAccountTransfer
                                : null,
                      ),
                      const SizedBox(height: 8),

                      // Date & Time
                      LedgerFormRow(
                        icon: Icons.access_time,
                        child: InkWell(
                          onTap: _pickDateTime,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat.yMMMEd(locale).format(_date),
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat.jm(locale).format(_date),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Note
                      LedgerFormRow(
                        icon: Icons.notes,
                        child: TextFormField(
                          initialValue: _note,
                          decoration: InputDecoration(
                            hintText: l10n.note,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            isDense: true,
                          ),
                          maxLines: null,
                          style: theme.textTheme.bodyLarge,
                          onSaved: (value) => _note = value,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const FeatherDivider(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          onPressed: _submit,
                          child: Text(l10n.saveTransaction),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One account picker. Used for both legs, which is why the field key,
  /// icon and labels are parameters.
  Widget _accountRow({
    required Key fieldKey,
    required IconData icon,
    required String title,
    required List<AccountEntity> options,
    required String? selectedId,
    required AppLocalizations l10n,
    required ValueChanged<String> onSelected,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);

    return LedgerFormRow(
      icon: icon,
      child: FormField<String>(
        key: fieldKey,
        initialValue: selectedId,
        validator: validator ?? (val) => val == null ? l10n.required : null,
        builder: (state) {
          final selected =
              options.where((a) => a.id == state.value).firstOrNull;
          return LedgerSelectorField(
            text: selected?.name ?? title,
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
            errorText: state.hasError ? state.errorText : null,
            onTap: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LedgerSelectionSheet<AccountEntity>(
                  title: title,
                  options: options,
                  getLabel: (a) => a.name,
                  // Each account's own currency, not the global display
                  // preference — a multi-currency ledger would otherwise
                  // label a JPY balance with a '$'.
                  getTrailing: (context, a) => Text(
                    '${AppCurrencies.getSymbol(a.currencyCode)}'
                    '${formatMinor(a.balanceMinor)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  getLeading: (context, a) => CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    child: Icon(a.type.icon),
                  ),
                  isSelected: (a) => a.id == state.value,
                  onSelected: (a) => Navigator.pop(context, a.id),
                  onManageTap: () => context.push('/accounts_management'),
                  manageButtonText: l10n.manageAccounts,
                ),
              );
              if (result != null) {
                state.didChange(result);
                onSelected(result);
              }
            },
          );
        },
      ),
    );
  }

  static AccountEntity? _resolve(List<AccountEntity> accounts, String? id) =>
      id == null ? null : accounts.where((a) => a.id == id).firstOrNull;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    setState(() {
      _date = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final vm = ref.read(ledgerViewModelProvider.notifier);
    final result = widget.transaction == null
        ? await vm.addTransfer(
            amountMinor: _amountMinor!,
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            date: _date,
            note: _note,
          )
        : await vm.updateTransfer(
            id: widget.transaction!.id,
            amountMinor: _amountMinor!,
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            date: _date,
            note: _note,
          );

    if (result case Failure(:final code)) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      }
      return;
    }
    if (mounted) context.pop();
  }
}
