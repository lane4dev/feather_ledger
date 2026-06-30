import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
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

import '../view_model/recurring_view_model.dart';
import 'ledger_amount_input.dart';
import 'ledger_form_row.dart';
import 'ledger_selection_sheet.dart';
import 'ledger_selector_field.dart';
import 'ledger_type_selector.dart';

/// Creates a recurring series (spec 004, US2 / FR-006).
///
/// Creation only — a series is changed by deactivating it and creating
/// another. Editing a rule that already produced instances raises questions
/// (re-materialize? delete future instances?) that this version does not
/// answer, and `countLimit` is left out for the same reason: one end
/// condition is enough for a person to reason about.
class RecurringSeriesFormSheet extends ConsumerStatefulWidget {
  const RecurringSeriesFormSheet({super.key});

  @override
  ConsumerState<RecurringSeriesFormSheet> createState() =>
      _RecurringSeriesFormSheetState();
}

class _RecurringSeriesFormSheetState
    extends ConsumerState<RecurringSeriesFormSheet> {
  final _formKey = GlobalKey<FormState>();

  RecurringSeriesKind _type = RecurringSeriesKind.expense;
  int? _amountMinor;
  String? _accountId;
  String? _categoryId;
  String? _description;
  String _frequency = 'MONTHLY';
  int _interval = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  CategoryType get _categoryType => _type == RecurringSeriesKind.income
      ? CategoryType.income
      : CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountListProvider);
    final categoriesAsync = ref.watch(categoryListProvider(_categoryType));

    return Padding(
      padding: EdgeInsets.only(
        left: context.spacing.lg,
        right: context.spacing.lg,
        top: context.spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + context.spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.newRecurringSeries,
                  style: theme.textTheme.titleLarge),
              SizedBox(height: context.spacing.md),

              LedgerTypeSelector(
                selectedType: _type.toTransactionKind,
                // A series has one account, so a transfer is not
                // representable — do not offer it (ADR-0002).
                kinds: const [
                  TransactionKind.expense,
                  TransactionKind.income,
                ],
                onSelectionChanged: (kind) => setState(() {
                  _type = kind == TransactionKind.income
                      ? RecurringSeriesKind.income
                      : RecurringSeriesKind.expense;
                  // A category of the old kind would be rejected by the
                  // posting context, so clear it rather than let the user
                  // submit and be refused.
                  _categoryId = null;
                }),
              ),
              SizedBox(height: context.spacing.lg),

              LedgerAmountInput(
                initialMinorUnits: _amountMinor,
                type: _type.toTransactionKind,
                onSaved: (minor) => _amountMinor = minor,
              ),
              const SizedBox(height: 8),
              const FeatherDivider(),

              LedgerFormRow(
                icon: Icons.notes,
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: l10n.seriesDescriptionHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? l10n.required
                          : null,
                  onSaved: (value) => _description = value?.trim(),
                ),
              ),

              LedgerFormRow(
                icon: Icons.account_balance_wallet_outlined,
                child: accountsAsync.when(
                  data: (accounts) => _Picker<AccountEntity>(
                    fieldKey: const ValueKey('series-account'),
                    placeholder: l10n.account,
                    options: accounts.where((a) => !a.archived).toList(),
                    selectedId: _accountId,
                    getLabel: (a) => a.name,
                    onSelected: (id) => setState(() => _accountId = id),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              LedgerFormRow(
                icon: Icons.grid_view_outlined,
                child: categoriesAsync.when(
                  data: (categories) => _Picker<CategoryEntity>(
                    // Re-keyed on type so a choice from the other list resets.
                    fieldKey: ValueKey('series-category-$_type'),
                    placeholder: l10n.category,
                    options: categories
                        .where((c) => c.type == _categoryType)
                        .toList(),
                    selectedId: _categoryId,
                    getLabel: (c) => c.name,
                    onSelected: (id) => setState(() => _categoryId = id),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
              ),

              LedgerFormRow(
                icon: Icons.repeat,
                child: _Picker<String>(
                  fieldKey: ValueKey('series-frequency-$_frequency'),
                  placeholder: l10n.seriesFrequency,
                  options: const ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'],
                  selectedId: _frequency,
                  getLabel: _frequencyLabel(l10n),
                  onSelected: (value) => setState(() => _frequency = value),
                ),
              ),

              LedgerFormRow(
                icon: Icons.timelapse,
                child: TextFormField(
                  initialValue: '$_interval',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: l10n.seriesInterval,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    return (parsed == null || parsed < 1)
                        ? l10n.seriesIntervalInvalid
                        : null;
                  },
                  onSaved: (value) => _interval = int.parse(value!),
                ),
              ),

              LedgerFormRow(
                icon: Icons.event,
                child: _DateRow(
                  label: l10n.seriesStartDate,
                  date: _startDate,
                  onTap: () => _pickDate(
                    initial: _startDate,
                    onPicked: (date) => setState(() => _startDate = date),
                  ),
                ),
              ),

              LedgerFormRow(
                icon: Icons.event_busy,
                child: _DateRow(
                  label: l10n.seriesEndDate,
                  date: _endDate,
                  placeholder: l10n.seriesEndDateNone,
                  onTap: () => _pickDate(
                    initial: _endDate ?? _startDate,
                    onPicked: (date) => setState(() => _endDate = date),
                  ),
                  onClear: _endDate == null
                      ? null
                      : () => setState(() => _endDate = null),
                ),
              ),

              SizedBox(height: context.spacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
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

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      // A bill can be backdated; far-future and far-past bounds just keep the
      // picker usable.
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) onPicked(picked);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final result =
        await ref.read(recurringViewModelProvider.notifier).createSeries(
              type: _type,
              amountMinor: _amountMinor!,
              accountId: _accountId!,
              categoryId: _categoryId!,
              description: _description!,
              frequency: _frequency,
              interval: _interval,
              startDate: _startDate,
              endDate: _endDate,
            );

    if (!mounted) return;
    if (result case Failure(:final code)) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    Navigator.pop(context);
  }
}

String Function(String) _frequencyLabel(AppLocalizations l10n) =>
    (value) => switch (value) {
          'DAILY' => l10n.frequencyDaily,
          'WEEKLY' => l10n.frequencyWeekly,
          'YEARLY' => l10n.frequencyYearly,
          _ => l10n.frequencyMonthly,
        };

/// A selector field backed by the shared bottom sheet.
class _Picker<T> extends StatelessWidget {
  const _Picker({
    required this.fieldKey,
    required this.placeholder,
    required this.options,
    required this.selectedId,
    required this.getLabel,
    required this.onSelected,
  });

  final Key fieldKey;
  final String placeholder;
  final List<T> options;
  final String? selectedId;
  final String Function(T) getLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return FormField<String>(
      key: fieldKey,
      initialValue: selectedId,
      validator: (value) => value == null ? l10n.required : null,
      builder: (state) {
        final selected = options
            .where((option) => _idOf(option) == state.value)
            .firstOrNull;
        return LedgerSelectorField(
          text: selected == null ? placeholder : getLabel(selected),
          textStyle: selected == null
              ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
              : null,
          errorText: state.hasError ? state.errorText : null,
          onTap: () async {
            final result = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => LedgerSelectionSheet<T>(
                title: placeholder,
                options: options,
                getLabel: getLabel,
                isSelected: (option) => _idOf(option) == state.value,
                onSelected: (option) => Navigator.pop(context, _idOf(option)),
              ),
            );
            if (result != null) {
              state.didChange(result);
              onSelected(result);
            }
          },
        );
      },
    );
  }

  /// Entities are identified by `id`; the plain [String] frequency is its own.
  String _idOf(T option) => option is String ? option : _entityId(option);

  String _entityId(T option) => switch (option) {
        AccountEntity(:final id) => id,
        CategoryEntity(:final id) => id,
        _ => option.toString(),
      };
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onTap,
    this.placeholder,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final String? placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = date == null
        ? (placeholder ?? label)
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-'
            '${date!.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: date == null
                    ? theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.hintColor)
                    : theme.textTheme.bodyLarge,
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
                tooltip: label,
              ),
          ],
        ),
      ),
    );
  }
}
