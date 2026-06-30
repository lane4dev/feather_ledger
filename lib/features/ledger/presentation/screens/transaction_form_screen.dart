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
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
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
import '../widgets/ledger_type_selector.dart';

/// Records or corrects any money movement: income, expense or transfer.
///
/// One form for all three because the user is describing one thing — an
/// amount, a date, and where it went. The kind only changes which fields
/// apply: a transfer has two accounts and no category. The fields that do not
/// apply to the selected kind are not rendered, so an illegal shape (a
/// transfer with a category, a transfer with one account) is not a state this
/// form can be in.
///
/// `null` means create, non-null means correct.
class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionTileUiModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Data
  int? _amountMinor;
  late TransactionKind _type;
  DateTime _date = DateTime.now();
  String? _note;

  /// The category for income/expense, and for a transfer the account the
  /// money leaves — the debit leg, which is the entity's primary account.
  String? _accountId;
  String? _categoryId;

  /// The credit leg. Only a transfer has one.
  String? _toAccountId;

  bool get _isTransfer => _type == TransactionKind.transfer;

  // Categories are typed by CategoryType, which has no transfer member; a
  // transfer has no category at all.
  CategoryType get _categoryType => _type == TransactionKind.income
      ? CategoryType.income
      : CategoryType.expense;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;
    if (transaction != null) {
      _amountMinor = transaction.amount;
      _type = transaction.type;
      _date = transaction.date;
      _note = transaction.note;
      _categoryId = transaction.category.id;
      _accountId = transaction.account.id;
      _toAccountId = transaction.toAccount?.id;
    } else {
      // A new transaction starts as an expense — the common case, and the one
      // the FAB is for.
      _type = TransactionKind.expense;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider(_categoryType));
    final accountsAsync = ref.watch(accountListProvider);
    final currencyKey = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.supportedCurrencyCodes.first;

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colorScheme = theme.colorScheme;

    // Pickers only offer non-archived accounts (spec 003, US3); history and
    // balances retain archived rows.
    final activeAccounts =
        (accountsAsync.value ?? const <AccountEntity>[])
            .where((a) => !a.archived)
            .toList();
    final fromAccount =
        activeAccounts.where((a) => a.id == _accountId).firstOrNull;

    // A transfer's legs are in the from-account's currency, so the amount is
    // labelled with that rather than the global display preference. The two
    // can differ, and silently showing the wrong symbol on money is worse than
    // showing none.
    final currencySymbol = _isTransfer
        ? AppCurrencies.getSymbol(
            fromAccount?.currencyCode ?? AppCurrencies.defaultCurrency.code)
        : AppCurrencies.getSymbol(currencyKey);

    // Same currency is an aggregate invariant, so the eligible destinations
    // are narrowed rather than letting the pair be chosen and refused. The
    // list is empty until a source is picked, which is also the honest answer.
    final toAccountOptions = activeAccounts
        .where((a) => a.id != _accountId)
        .where((a) =>
            fromAccount == null ||
            a.currencyCode == fromAccount.currencyCode)
        .toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(_title(l10n)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.lg, vertical: context.spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kind Toggle
              LedgerTypeSelector(
                selectedType: _type,
                onSelectionChanged: _onTypeChanged,
              ),
              const SizedBox(height: 32),

              // 2. Amount Input
              LedgerAmountInput(
                initialMinorUnits: _amountMinor,
                type: _type,
                currencySymbol: currencySymbol,
                autofocus: widget.transaction == null,
                onSaved: (minor) => _amountMinor = minor,
              ),
              const SizedBox(height: 32),

              const FeatherDivider(),
              const SizedBox(height: 16),

              // 3. Date & Time
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
                          DateFormat.yMMMEd(locale)
                              .format(_date), // e.g., Sat, Jan 20
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.jm(locale).format(_date), // e.g., 5:08 PM
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 4. Category — income and expense only.
              if (!_isTransfer)
                LedgerFormRow(
                  icon: Icons.grid_view_outlined,
                  child: categoriesAsync.when(
                    data: (categories) {
                      final filtered = categories
                          .where((c) => c.type == _categoryType)
                          .toList();
                      return FormField<String>(
                        key: ValueKey('category-$_type'),
                        initialValue: _categoryId,
                        validator: (val) => val == null ? l10n.required : null,
                        builder: (state) {
                          final selected = filtered
                              .where((c) => c.id == state.value)
                              .firstOrNull;
                          return LedgerSelectorField(
                            text: selected?.name ?? l10n.category,
                            textStyle: selected == null
                                ? theme.textTheme.bodyLarge
                                    ?.copyWith(color: theme.hintColor)
                                : null,
                            errorText: state.hasError ? state.errorText : null,
                            onTap: () async {
                              final result =
                                  await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (context) =>
                                    LedgerSelectionSheet<CategoryEntity>(
                                  title: l10n.category,
                                  options: filtered,
                                  getLabel: (c) => c.name,
                                  getIcon: (c) => IconData(
                                    int.tryParse(c.iconKey) ?? 0xe574,
                                    fontFamily: 'MaterialIcons',
                                  ),
                                  getColor: (c) => Color(c.colorInt),
                                  isSelected: (c) => c.id == state.value,
                                  onSelected: (c) =>
                                      Navigator.pop(context, c.id),
                                  onManageTap: () =>
                                      context.push('/categories_management'),
                                  manageButtonText: l10n.manageCategories,
                                ),
                              );
                              if (result != null) {
                                state.didChange(result);
                                setState(() => _categoryId = result);
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                  ),
                ),

              if (!_isTransfer) const SizedBox(height: 8),

              // 5. Account(s). A transfer gets both legs; income and expense
              //    get the single account the money lands in or leaves.
              _accountRow(
                fieldKey: ValueKey('account-$_type'),
                icon: _isTransfer
                    ? Icons.arrow_upward
                    : Icons.account_balance_wallet_outlined,
                // A transfer's debit leg is its "from" side, and saying so is
                // the whole point of the screen — the same labels the detail
                // sheet uses.
                placeholder: _isTransfer ? l10n.transferFrom : l10n.account,
                options: activeAccounts,
                selectedId: _accountId,
                onSelected: (id) => setState(() {
                  _accountId = id;
                  // The destination is keyed on the source, so re-keying
                  // resets a choice the currency filter may no longer offer.
                  _toAccountId = null;
                }),
              ),

              if (_isTransfer) ...[
                const SizedBox(height: 8),
                _accountRow(
                  fieldKey: ValueKey('to-account-$_accountId'),
                  icon: Icons.arrow_downward,
                  placeholder: l10n.transferTo,
                  options: toAccountOptions,
                  selectedId: _toAccountId,
                  onSelected: (id) => setState(() => _toAccountId = id),
                  // Defence in depth: the options already exclude it, but the
                  // aggregate is the real guard and this keeps an unreachable
                  // state from becoming reachable through a refactor.
                  extraValidator: (value) =>
                      value != null && value == _accountId
                          ? l10n.errorSameAccountTransfer
                          : null,
                ),
              ],

              const SizedBox(height: 8),

              // 6. Note
              LedgerFormRow(
                icon: Icons.notes,
                child: TextFormField(
                  initialValue: _note,
                  decoration: InputDecoration(
                    hintText: l10n.note,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    if (widget.transaction == null) {
      return _isTransfer ? l10n.addTransfer : l10n.addTransaction;
    }
    return _isTransfer ? l10n.editTransfer : l10n.editTransaction;
  }

  /// Switching kind clears what the new kind cannot carry, rather than
  /// leaving a value in a field it does not render.
  void _onTypeChanged(TransactionKind type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      _toAccountId = null;
    });
  }

  /// One account field, used for all three kinds: the single account of an
  /// income/expense, and each leg of a transfer.
  Widget _accountRow({
    required Key fieldKey,
    required IconData icon,
    required String placeholder,
    required List<AccountEntity> options,
    required String? selectedId,
    required ValueChanged<String> onSelected,
    FormFieldValidator<String>? extraValidator,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return LedgerFormRow(
      icon: icon,
      child: FormField<String>(
        key: fieldKey,
        initialValue: selectedId,
        validator: (value) {
          if (value == null) return l10n.required;
          return extraValidator?.call(value);
        },
        builder: (state) {
          final selected =
              options.where((a) => a.id == state.value).firstOrNull;
          return LedgerSelectorField(
            text: selected?.name ?? placeholder,
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
                  title: placeholder,
                  options: options,
                  getLabel: (a) => a.name,
                  // Each account's own currency, not the global display
                  // preference: with transfers in this form the two legs can
                  // be read side by side, and a shared symbol would mislabel
                  // one of them whenever the accounts differ.
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

    if (_isTransfer) {
      await _finish(_saveTransfer());
      return;
    }

    // Overdraft check — an expense takes money out of an account it must be
    // able to cover. A transfer's debit leg is the same question, but its
    // semantics are genuinely ambiguous when both legs are the user's own
    // money, so it is left alone until that is decided.
    if (_type == TransactionKind.expense && _accountId != null) {
      final accounts = ref.read(accountListProvider).value;
      final account = accounts?.where((a) => a.id == _accountId).firstOrNull;

      if (account != null && account.wouldOverdraft(_amountMinor!)) {
        final l10n = AppLocalizations.of(context)!;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.overdraftWarningTitle),
            content: Text(l10n.overdraftWarningMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }
    }

    final vm = ref.read(ledgerViewModelProvider.notifier);
    await _finish(
      widget.transaction == null
          ? vm.addTransaction(
              amountMinor: _amountMinor!,
              type: _type,
              date: _date,
              categoryId: _categoryId!,
              accountId: _accountId!,
              note: _note,
            )
          : vm.updateTransaction(
              id: widget.transaction!.id,
              amountMinor: _amountMinor!,
              type: _type,
              date: _date,
              categoryId: _categoryId!,
              accountId: _accountId!,
              note: _note,
            ),
    );
  }

  /// A transfer has no category, and takes the two accounts instead.
  Future<Result<void>> _saveTransfer() {
    final vm = ref.read(ledgerViewModelProvider.notifier);
    return widget.transaction == null
        ? vm.addTransfer(
            amountMinor: _amountMinor!,
            fromAccountId: _accountId!,
            toAccountId: _toAccountId!,
            date: _date,
            note: _note,
          )
        : vm.updateTransfer(
            id: widget.transaction!.id,
            amountMinor: _amountMinor!,
            fromAccountId: _accountId!,
            toAccountId: _toAccountId!,
            date: _date,
            note: _note,
          );
  }

  /// Reports the outcome and closes on success — the one place a failure is
  /// rendered, shared by every kind.
  Future<void> _finish(Future<Result<void>> write) async {
    final result = await write;
    if (!mounted) return;

    if (result case Failure(:final code)) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    context.pop();
  }
}
