import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Amount
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final p = double.tryParse(value);
                  if (p == null || p <= 0) return 'Invalid amount';
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // 2. Type
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.add_circle_outline)),
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
              const SizedBox(height: 16),

              // 3. Date
              ListTile(
                title: const Text('Date'),
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
                    return const Text(
                        'No categories found. Please add some first.');
                  }
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Category'),
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
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _categoryId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),

              // 5. Account
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) return const Text('No accounts found.');
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Account'),
                    value: _accountId,
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _accountId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),

              // 6. Note
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note'),
                onSaved: (value) => _note = value,
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: _submit,
                child: const Text('Save Transaction'),
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
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
