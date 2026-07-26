import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';
import '../theme/ledger_theme.dart';
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

  /// The bill's amount, as the text the field shows. Read back through
  /// [parseMinor] when it is saved — the field holds no value of its own.
  late final TextEditingController _amount;
  late DateTime _date;
  String? _categoryId;
  String? _accountId;
  late final TextEditingController _note;

  /// Whether the user changed something only the series can hold. If they
  /// did, "only this bill" stops being an answer this edit can have.
  bool get _changedSeriesFields =>
      _categoryId != widget.transaction.category!.id ||
      _accountId != widget.transaction.account.id ||
      _note.text.trim() != (widget.transaction.note ?? '').trim();

  @override
  void initState() {
    super.initState();
    final bill = widget.transaction;
    _amount = TextEditingController(text: formatMinor(bill.amount));
    _date = bill.date;
    _categoryId = bill.category!.id;
    _accountId = bill.account.id;
    _note = TextEditingController(text: bill.note ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
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
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.editRecurringTitle),
      ),
      body: SingleChildScrollView(
        // No horizontal padding: a row insets its own contents so its ripple
        // can reach the edge, and padding it from out here would clip that
        // ripple. Everything in the column that is not a row is wrapped in
        // [_inset].
        padding: EdgeInsets.symmetric(vertical: context.spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inset(
                LedgerAmountInput(
                  controller: _amount,
                  type: widget.transaction.type,
                  currencySymbol: currency,
                ),
              ),
              SizedBox(height: context.spacing.lg),
              _inset(const FeatherDivider()),
              SizedBox(height: context.spacing.md),
              _dateRow(l10n),
              SizedBox(height: context.spacing.sm),
              _categoryRow(l10n),
              SizedBox(height: context.spacing.sm),
              _accountRow(l10n),
              SizedBox(height: context.spacing.sm),
              LedgerFormRow(
                icon: LucideIcons.notebookPen,
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
              _inset(
                FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The page's horizontal margin, for the column's children that are not
  /// [LedgerFormRow]s. A row insets itself so that its ripple can reach the
  /// edge; anything else has to be inset from out here.
  Widget _inset(Widget child) => Padding(
        padding: LedgerTheme.pageInset(context),
        child: child,
      );

  Widget _dateRow(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    return LedgerFormRow(
      icon: LucideIcons.calendar,
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

    final categories = ref.watch(categoryListProvider(categoryType));

    return LedgerFormRow(
      icon: LucideIcons.layoutGrid,
      onTap: categories.value == null
          ? null
          : () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LedgerSelectionSheet<CategoryEntity>(
                  title: l10n.category,
                  options: categories.value!,
                  getLabel: (c) => c.name,
                  isSelected: (c) => c.id == _categoryId,
                  onSelected: (c) => Navigator.pop(context, c.id),
                  onManageTap: () => context.push('/categories_management'),
                  manageButtonText: l10n.manageCategories,
                ),
              );
              if (result != null) setState(() => _categoryId = result);
            },
      child: categories.when(
        data: (categories) {
          final selected =
              categories.where((c) => c.id == _categoryId).firstOrNull;
          return LedgerSelectorField(
            text: selected?.name ?? l10n.category,
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
          );
        },
        loading: () => const SizedBox(height: 24),
        error: (_, __) => const SizedBox(height: 24),
      ),
    );
  }

  Widget _accountRow(AppLocalizations l10n) {
    final theme = Theme.of(context);

    final accounts = ref.watch(accountUiListProvider);

    return LedgerFormRow(
      icon: LucideIcons.wallet,
      onTap: accounts.value == null
          ? null
          : () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LedgerSelectionSheet<AccountUiModel>(
                  title: l10n.account,
                  options: accounts.value!,
                  getLabel: (a) => a.account.name,
                  isSelected: (a) => a.account.id == _accountId,
                  onSelected: (a) => Navigator.pop(context, a.account.id),
                  onManageTap: () => context.push('/accounts_management'),
                  manageButtonText: l10n.manageAccounts,
                ),
              );
              if (result != null) setState(() => _accountId = result);
            },
      child: accounts.when(
        data: (accounts) {
          final selected =
              accounts.where((a) => a.account.id == _accountId).firstOrNull;
          return LedgerSelectorField(
            text: selected?.account.name ?? l10n.account,
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
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
      _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute);
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Asked here, not on the way in: the question is "how far does *this*
    // edit reach", and there is no this until the fields are filled.
    final scope = await showDialog<RecurringScope>(
      context: context,
      builder: (context) => RecurringScopeDialog(
        title: l10n.saveRecurringTitle,
        confirmLabel: l10n.save,
        unavailable:
            _changedSeriesFields ? const {RecurringScope.thisOnly} : const {},
        unavailableHint: l10n.scopeThisOnlyUnavailable,
      ),
    );
    if (scope == null || !mounted) return;

    final result =
        await ref.read(recurringViewModelProvider.notifier).updateBill(
              widget.transaction.id,
              scope: scope,
              amountMinor: parseMinor(_amount.text),
              date: _date,
              categoryId: _categoryId ?? widget.transaction.category!.id,
              accountId: _accountId ?? widget.transaction.account.id,
              description: _note.text.trim().isEmpty
                  ? widget.transaction.category!.name
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
