import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/recurring_view_model.dart';
import '../widgets/ledger_amount_input.dart';
import '../widgets/ledger_form_row.dart';
import '../widgets/ledger_selection_sheet.dart';
import '../widgets/ledger_selector_field.dart';
import '../widgets/recurring_scope_dialog.dart';

/// Edits one upcoming recurring bill (spec 004, US2).
///
/// The form shows every field and asks how far the change reaches *when it is
/// saved*. One field does not survive every answer: a bill's date and amount
/// live on the instance row, while its category, account and description live
/// on the series. So a change to those three cannot be applied to a single
/// occurrence — and the dialog says so by refusing that scope, rather than
/// accepting the edit and quietly dropping half of it.
class RecurringBillFormScreen extends ConsumerStatefulWidget {
  const RecurringBillFormScreen({
    super.key,
    required this.transaction,
  });

  final TransactionTileUiModel transaction;

  @override
  ConsumerState<RecurringBillFormScreen> createState() =>
      _RecurringBillFormScreenState();
}

class _RecurringBillFormScreenState
    extends ConsumerState<RecurringBillFormScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _amountMinor;
  late DateTime _date;
  String? _categoryId;
  String? _accountId;
  late final TextEditingController _note;

  /// Whether the user changed something only the series can hold. If they
  /// did, "only this bill" stops being an answer this edit can have.
  bool get _changedSeriesFields =>
      _categoryId != widget.transaction.category.id ||
      _accountId != widget.transaction.account.id ||
      _note.text.trim() != (widget.transaction.note ?? '').trim();

  @override
  void initState() {
    super.initState();
    final bill = widget.transaction;
    _amountMinor = bill.amount;
    _date = bill.date;
    _categoryId = bill.category.id;
    _accountId = bill.account.id;
    _note = TextEditingController(text: bill.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency = AppCurrencies.defaultCurrency.symbol;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.editRecurringTitle),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.lg,
          vertical: context.spacing.md,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LedgerAmountInput(
                initialMinorUnits: _amountMinor,
                type: widget.transaction.type,
                currencySymbol: currency,
                onSaved: (minor) => _amountMinor = minor,
              ),
              SizedBox(height: context.spacing.lg),

              const FeatherDivider(),
              SizedBox(height: context.spacing.md),

              _dateRow(l10n),
              SizedBox(height: context.spacing.sm),

              _categoryRow(l10n),
              SizedBox(height: context.spacing.sm),
              _accountRow(l10n),
              SizedBox(height: context.spacing.sm),
              LedgerFormRow(
                icon: Icons.edit_note,
                child: TextFormField(
                  controller: _note,
                  decoration: InputDecoration(
                    hintText: l10n.note,
                    border: InputBorder.none,
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),

              SizedBox(height: context.spacing.xl),
              FilledButton(
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    return LedgerFormRow(
      icon: Icons.event,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            DateFormat.yMMMMEEEEd(locale).format(_date),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final categoryType = widget.transaction.type == TransactionKind.income
        ? CategoryType.income
        : CategoryType.expense;

    return LedgerFormRow(
      icon: Icons.grid_view_outlined,
      child: ref.watch(categoryListProvider(categoryType)).when(
            data: (categories) {
              final selected =
                  categories.where((c) => c.id == _categoryId).firstOrNull;
              return LedgerSelectorField(
                text: selected?.name ?? l10n.category,
                textStyle: selected == null
                    ? theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.hintColor)
                    : null,
                onTap: () async {
                  final result =
                      await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => LedgerSelectionSheet<CategoryEntity>(
                      title: l10n.category,
                      options: categories,
                      getLabel: (c) => c.name,
                      isSelected: (c) => c.id == _categoryId,
                      onSelected: (c) => Navigator.pop(context, c.id),
                      onManageTap: () => context.push('/categories_management'),
                      manageButtonText: l10n.manageCategories,
                    ),
                  );
                  if (result != null) setState(() => _categoryId = result);
                },
              );
            },
            loading: () => const SizedBox(height: 24),
            error: (_, __) => const SizedBox(height: 24),
          ),
    );
  }

  Widget _accountRow(AppLocalizations l10n) {
    final theme = Theme.of(context);

    return LedgerFormRow(
      icon: Icons.account_balance_wallet_outlined,
      child: ref.watch(accountListProvider).when(
            data: (accounts) {
              final selected =
                  accounts.where((a) => a.id == _accountId).firstOrNull;
              return LedgerSelectorField(
                text: selected?.name ?? l10n.account,
                textStyle: selected == null
                    ? theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.hintColor)
                    : null,
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => LedgerSelectionSheet<AccountEntity>(
                      title: l10n.account,
                      options: accounts,
                      getLabel: (a) => a.name,
                      isSelected: (a) => a.id == _accountId,
                      onSelected: (a) => Navigator.pop(context, a.id),
                      onManageTap: () => context.push('/accounts_management'),
                      manageButtonText: l10n.manageAccounts,
                    ),
                  );
                  if (result != null) setState(() => _accountId = result);
                },
              );
            },
            loading: () => const SizedBox(height: 24),
            error: (_, __) => const SizedBox(height: 24),
          ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    // Day only. The bill keeps the rule's clock time, which is an artefact of
    // when the series was created and not something the user set.
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour,
          _date.minute);
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    // `save()` as well as `validate()`: the amount field reports itself
    // through `onSaved`, which validating alone never runs.
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    // Asked here, not on the way in: the question is "how far does *this*
    // edit reach", and there is no this until the fields are filled.
    final scope = await showDialog<RecurringScope>(
      context: context,
      builder: (context) => RecurringScopeDialog(
        title: l10n.saveRecurringTitle,
        confirmLabel: l10n.save,
        unavailable: _changedSeriesFields
            ? const {RecurringScope.thisOnly}
            : const {},
        unavailableHint: l10n.scopeThisOnlyUnavailable,
      ),
    );
    if (scope == null || !mounted) return;

    final result = await ref
        .read(recurringViewModelProvider.notifier)
        .updateBill(
          widget.transaction.id,
          scope: scope,
          amountMinor: _amountMinor!,
          date: _date,
          categoryId: _categoryId ?? widget.transaction.category.id,
          accountId: _accountId ?? widget.transaction.account.id,
          description: _note.text.trim().isEmpty
              ? widget.transaction.category.name
              : _note.text.trim(),
        );

    if (!mounted) return;

    if (result case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    context.pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.billUpdated)));
  }
}
