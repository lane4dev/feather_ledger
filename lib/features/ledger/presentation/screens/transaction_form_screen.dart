import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/tables.dart';
import '../../domain/services/ledger_service.dart';
import '../providers/ledger_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

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
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(allAccountsProvider);
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addTransaction),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Amount
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixText: '\$ ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.required;
                  final p = double.tryParse(value);
                  if (p == null || p <= 0) return l10n.invalidAmount;
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              SizedBox(height: spacing.md),

              // 2. Type
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expense),
                      icon: const Icon(Icons.remove_circle_outline)),
                  ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.income),
                      icon: const Icon(Icons.add_circle_outline)),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    // Reset category if type changes? For MVP, maybe not strictly enforced by UI but good UX.
                    _categoryId = null;
                  });
                },
              ),
              SizedBox(height: spacing.md),

              // 3. Date
              ListTile(
                title: Text(l10n.date),
                subtitle: Text(DateFormat.yMMMd().format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),
              const Divider(),

              // 4. Category
              categoriesAsync.when(
                data: (categories) {
                  // Filter categories by type
                  final filtered =
                      categories.where((c) => c.type == _type).toList();
                  if (filtered.isEmpty) {
                    return Text(l10n.noCategoriesFound);
                  }
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: l10n.category),
                    value: _categoryId,
                    items: filtered
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  Icon(IconData(
                                      int.tryParse(c.iconKey) ?? 0xe574,
                                      fontFamily:
                                          'MaterialIcons')), // Fallback icon
                                  SizedBox(width: spacing.sm),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _categoryId = val),
                    validator: (val) => val == null ? l10n.required : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text(l10n.errorPrefix(e.toString())),
              ),
              SizedBox(height: spacing.md),

              // 5. Account
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) return Text(l10n.noAccountsFound);
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: l10n.account),
                    value: _accountId,
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _accountId = val),
                    validator: (val) => val == null ? l10n.required : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text(l10n.errorPrefix(e.toString())),
              ),
              SizedBox(height: spacing.md),

              // 6. Note
              TextFormField(
                decoration: InputDecoration(labelText: l10n.note),
                onSaved: (value) => _note = value,
              ),
              SizedBox(height: spacing.xl),

              // Save Button
              FilledButton(
                onPressed: _submit,
                child: Text(l10n.saveTransaction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await ref.read(ledgerServiceProvider).addTransaction(
              amount: _amount!,
              type: _type,
              date: _date,
              categoryId: _categoryId!,
              accountId: _accountId!,
              note: _note,
            );
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
