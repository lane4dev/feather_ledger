import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/value_objects/transaction_filter.dart';
import 'ledger_form_row.dart';
import 'ledger_selection_sheet.dart';
import 'ledger_selector_field.dart';

/// The filter editor (spec 004, US3 / FR-014).
///
/// Holds a mutable draft and returns one immutable [TransactionFilter] on
/// Apply, which is why [TransactionFilter] has no `copyWith`: a nullable
/// field's `copyWith` needs sentinels to express "clear this", and a draft
/// with a `null`-means-unset convention is the same problem in a nicer hat.
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key, required this.initial});

  final TransactionFilter initial;

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late TransactionKind? _kind = widget.initial.kind;
  late String? _accountId = widget.initial.accountId;
  late String? _categoryId = widget.initial.categoryId;
  late DateTime? _from = widget.initial.from;
  late DateTime? _to = widget.initial.to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountListProvider);
    // Both kinds: a filter is not the place to make the user remember which
    // side a category lives on.
    final expenseCategories = ref.watch(categoryListProvider(CategoryType.expense));
    final incomeCategories = ref.watch(categoryListProvider(CategoryType.income));
    final categories = [
      ...expenseCategories.value ?? const <CategoryEntity>[],
      ...incomeCategories.value ?? const <CategoryEntity>[],
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: context.spacing.lg,
        right: context.spacing.lg,
        top: context.spacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + context.spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.filterTitle,
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: context.spacing.md),

            // Kind
            LedgerFormRow(
              icon: LucideIcons.arrowUpDown,
              child: _ChipRow<TransactionKind?>(
                values: const [
                  null,
                  TransactionKind.income,
                  TransactionKind.expense,
                  TransactionKind.transfer,
                ],
                selected: _kind,
                labelOf: (kind) => switch (kind) {
                  null => l10n.filterAllKinds,
                  TransactionKind.income => l10n.income,
                  TransactionKind.expense => l10n.expense,
                  TransactionKind.transfer => l10n.transfer,
                },
                onSelected: (kind) => setState(() => _kind = kind),
              ),
            ),

            // Account
            LedgerFormRow(
              icon: LucideIcons.wallet,
              child: accountsAsync.when(
                data: (accounts) => _EntityPicker<AccountEntity>(
                  fieldKey: ValueKey('filter-account-$_accountId'),
                  placeholder: l10n.filterAnyAccount,
                  options: accounts,
                  selectedId: _accountId,
                  getLabel: (a) => a.name,
                  onSelected: (id) => setState(() => _accountId = id),
                  onClear: () => setState(() => _accountId = null),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // Category
            LedgerFormRow(
              icon: LucideIcons.layoutGrid,
              child: _EntityPicker<CategoryEntity>(
                fieldKey: ValueKey('filter-category-$_categoryId'),
                placeholder: l10n.filterAnyCategory,
                options: categories,
                selectedId: _categoryId,
                getLabel: (c) => c.name,
                onSelected: (id) => setState(() => _categoryId = id),
                onClear: () => setState(() => _categoryId = null),
              ),
            ),

            // Date range
            LedgerFormRow(
              icon: LucideIcons.calendarRange,
              child: InkWell(
                onTap: _pickRange,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _rangeLabel(l10n),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),

            SizedBox(height: context.spacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    outlined: true,
                    onPressed: () => Navigator.pop(
                      context,
                      // An empty filter, not null: the caller can tell
                      // "cleared" from "dismissed".
                      TransactionFilter.empty,
                    ),
                    child: Text(l10n.filterClear),
                  ),
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: AppButton(
                    onPressed: () => Navigator.pop(context, _build()),
                    child: Text(l10n.filterApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TransactionFilter _build() => TransactionFilter(
        kind: _kind,
        accountId: _accountId,
        categoryId: _categoryId,
        from: _from,
        to: _to,
      );

  String _rangeLabel(AppLocalizations l10n) {
    if (_from == null && _to == null) return l10n.filterAnyDate;
    String format(DateTime date) => '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${_from == null ? '…' : format(_from!)}'
        ' – '
        '${_to == null ? '…' : format(_to!)}';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      // Clearing is done by picking again, so offer a way back to unbounded.
      helpText: AppLocalizations.of(context)!.filterDateRange,
    );
    if (picked == null) return;
    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
  }
}

/// A row of single-choice chips, including a "no filter" choice.
class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: values
            .map((value) => ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: value == selected,
                  onSelected: (_) => onSelected(value),
                ))
            .toList(),
      );
}

/// A nullable entity selector: shows a placeholder when unset and offers a
/// clear affordance once set.
class _EntityPicker<T> extends StatelessWidget {
  const _EntityPicker({
    required this.fieldKey,
    required this.placeholder,
    required this.options,
    required this.selectedId,
    required this.getLabel,
    required this.onSelected,
    required this.onClear,
  });

  final Key fieldKey;
  final String placeholder;
  final List<T> options;
  final String? selectedId;
  final String Function(T) getLabel;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  String _idOf(T option) => switch (option) {
        AccountEntity(:final id) => id,
        CategoryEntity(:final id) => id,
        _ => option.toString(),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected =
        options.where((o) => _idOf(o) == selectedId).firstOrNull;

    return Row(
      children: [
        Expanded(
          child: LedgerSelectorField(
            text: selected == null ? placeholder : getLabel(selected),
            textStyle: selected == null
                ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                : null,
            onTap: () async {
              final result = await showModalBottomSheet<String>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => LedgerSelectionSheet<T>(
                  title: placeholder,
                  options: options,
                  getLabel: getLabel,
                  isSelected: (option) => _idOf(option) == selectedId,
                  onSelected: (option) =>
                      Navigator.pop(context, _idOf(option)),
                ),
              );
              if (result != null) onSelected(result);
            },
          ),
        ),
        if (selected != null)
          IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: onClear,
            tooltip: placeholder,
          ),
      ],
    );
  }
}
