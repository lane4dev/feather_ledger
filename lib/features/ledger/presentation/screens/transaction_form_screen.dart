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

// import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';

import '../view_model/ledger_view_model.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
import '../widgets/ledger_selection_sheet.dart';
import '../widgets/ledger_selector_field.dart';
import '../widgets/ledger_type_selector.dart';

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
  TransactionKind _type = TransactionKind.expense;
  DateTime _date = DateTime.now();
  String? _note;
  String? _categoryId;
  String? _accountId;

  // Category repositories are typed by CategoryType; the transaction form
  // only exposes income/expense kinds.
  CategoryType get _categoryType => _type == TransactionKind.income
      ? CategoryType.income
      : CategoryType.expense;

  @override
  void initState() {
    super.initState();

    if (widget.transaction != null) {
      _amountMinor = widget.transaction!.amount;
      _type = widget.transaction!.type;
      _date = widget.transaction!.date;
      _note = widget.transaction!.note;
      _categoryId = widget.transaction!.category.id;
      _accountId = widget.transaction!.account.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider(_categoryType));
    final accountsAsync = ref.watch(accountListProvider);
    final currencyKey = ref.watch(currencyControllerProvider).value ??
        AppCurrencies.supportedCurrencyCodes.first;
    final currencySymbol = AppCurrencies.getSymbol(currencyKey);

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
            ? l10n.addTransaction
            : l10n.editTransaction),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.lg, vertical: context.spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transaction Type Toggle
              LedgerTypeSelector(
                selectedType: _type,
                onSelectionChanged: (type) {
                  setState(() {
                    _type = type;
                    _categoryId = null; // Reset category on type change
                  });
                },
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

              // 4. Category
              LedgerFormRow(
                icon: Icons.grid_view_outlined,
                child: categoriesAsync.when(
                  data: (categories) {
                    final filtered = categories
                        .where((c) => c.type == _categoryType)
                        .toList();
                    return FormField<String>(
                      key: ValueKey(_type),
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
                            final result = await showModalBottomSheet<String>(
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
                                onSelected: (c) => Navigator.pop(context, c.id),
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

              const SizedBox(height: 8),

              // 5. Account
              LedgerFormRow(
                icon: Icons.account_balance_wallet_outlined,
                child: accountsAsync.when(
                  data: (accounts) {
                    // Pickers only offer non-archived accounts (spec 003,
                    // US3); history and balances retain archived rows.
                    final activeAccounts =
                        accounts.where((a) => !a.archived).toList();
                    return FormField<String>(
                      initialValue: _accountId,
                      validator: (val) => val == null ? l10n.required : null,
                      builder: (state) {
                        final selected = activeAccounts
                            .where((a) => a.id == state.value)
                            .firstOrNull;
                        return LedgerSelectorField(
                          text: selected?.name ?? l10n.account,
                          textStyle: selected == null
                              ? theme.textTheme.bodyLarge
                                  ?.copyWith(color: theme.hintColor)
                              : null,
                          errorText: state.hasError ? state.errorText : null,
                          onTap: () async {
                            final result = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) =>
                                  LedgerSelectionSheet<AccountEntity>(
                                title: l10n.account,
                                options: activeAccounts,
                                getLabel: (a) => a.name,
                                getTrailing: (context, a) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$currencySymbol${formatMinor(a.balanceMinor)}',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    if (a.id == state.value) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.check,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ],
                                  ],
                                ),
                                getLeading: (context, a) => CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  child: Icon(a.type.icon),
                                ),
                                isSelected: (a) => a.id == state.value,
                                onSelected: (a) => Navigator.pop(context, a.id),
                                onManageTap: () =>
                                    context.push('/accounts_management'),
                                manageButtonText: l10n.manageAccounts,
                              ),
                            );
                            if (result != null) {
                              state.didChange(result);
                              setState(() => _accountId = result);
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

    if (time != null) {
      setState(() {
        _date = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    } else {
      setState(() {
        _date = DateTime(
          date.year,
          date.month,
          date.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Overdraft check
      if (_type == TransactionKind.expense && _accountId != null) {
        final accounts = ref.read(accountListProvider).value;
        final account = accounts?.where((a) => a.id == _accountId).firstOrNull;

        if (account != null && account.type != AccountType.credit) {
          if (account.balanceMinor - _amountMinor! < 0) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('warning'),
                content: const Text(
                    'This transaction will cause an overdraft. Continue?'), // Ideally localized
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ],
              ),
            );

            if (confirm != true) return;
          }
        }
      }

      final vm = ref.read(ledgerViewModelProvider.notifier);
      final result = widget.transaction == null
          ? await vm.addTransaction(
              amountMinor: _amountMinor!,
              type: _type,
              date: _date,
              categoryId: _categoryId!,
              accountId: _accountId!,
              note: _note,
            )
          : await vm.updateTransaction(
              id: widget.transaction!.id,
              amountMinor: _amountMinor!,
              type: _type,
              date: _date,
              categoryId: _categoryId!,
              accountId: _accountId!,
              note: _note,
            );

      if (result case Failure(:final code)) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(code.message(l10n))));
        }
        return;
      }
      if (mounted) context.pop();
    }
  }
}
