import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Added import
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/enums.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/app/config/app_currencies.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/ledger_service.dart';
// import '../providers/ledger_providers.dart';

import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
import '../widgets/ledger_selection_sheet.dart';
import '../widgets/ledger_selector_field.dart';
import '../widgets/ledger_type_selector.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Data
  double? _amount;
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _note;
  int? _categoryId;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amount = widget.transaction!.amount;
      _type = widget.transaction!.type;
      _date = widget.transaction!.date;
      _note = widget.transaction!.note;
      _categoryId = widget.transaction!.category.id;
      _accountId = widget.transaction!.account.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider(_type));
    final accountsAsync = ref.watch(accountListProvider);
    final currencyKey = ref.watch(currencyControllerProvider).valueOrNull ??
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
              // Centered segmented button, clean look
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
              // Big, bold, colored
              LedgerAmountInput(
                initialValue: _amount,
                type: _type,
                currencySymbol: currencySymbol,
                autofocus: widget.transaction == null,
                onSaved: (value) => _amount = double.parse(value!),
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
                icon: Icons.grid_view_outlined, // or local_offer_outlined
                child: categoriesAsync.when(
                  data: (categories) {
                    final filtered =
                        categories.where((c) => c.type == _type).toList();
                    return FormField<int>(
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
                            final result = await showModalBottomSheet<int>(
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
                    return FormField<int>(
                      initialValue: _accountId,
                      validator: (val) => val == null ? l10n.required : null,
                      builder: (state) {
                        final selected = accounts
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
                            final result = await showModalBottomSheet<int>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) =>
                                  LedgerSelectionSheet<AccountEntity>(
                                title: l10n.account,
                                options: accounts,
                                getLabel: (a) => a.name,
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
                child: FilledButton(
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
      // User cancelled time, still save date but keep old time?
      // Or just default to 00:00?
      // Usually better to keep current time or reset.
      // Let's just update date and keep current time if user cancels time picker?
      // No, standard flow is if you pick date, you expect that date.
      // But we asked for time accuracy.
      // Let's assume if they cancel time, they didn't mean to change the whole thing?
      // Or we can just use the date with existing time.
      // Let's simple combine date + picked time.

      // If time is null (cancelled), we typically keep the previous time part
      // but strictly we just picked a NEW date.
      // Let's just update the date part and keep the time part of `_date`.
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

      try {
        final service = ref.read(ledgerServiceProvider);
        if (widget.transaction == null) {
          await service.addTransaction(
            amount: _amount!,
            type: _type,
            date: _date,
            categoryId: _categoryId!,
            accountId: _accountId!,
            note: _note,
          );
        } else {
          await service.updateTransaction(
            id: widget.transaction!.id,
            amount: _amount!,
            type: _type,
            date: _date,
            categoryId: _categoryId!,
            accountId: _accountId!,
            note: _note,
          );
        }
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorPrefix(e.toString()))));
        }
      }
    }
  }
}
