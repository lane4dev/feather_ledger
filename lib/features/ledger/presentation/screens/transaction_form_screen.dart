import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/database/tables.dart';
import '../../../../shared/presentation/widgets/feather_divider.dart';
import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/ledger_service.dart';
import '../providers/ledger_providers.dart';

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
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(allAccountsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _type == TransactionType.income
        ? context.colors.income
        : context.colors.expense;

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
              Center(
                child: SegmentedButton<TransactionType>(
                  segments: [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expense),
                      // icon: const Icon(Icons.remove_circle_outline), // Icon can be noisy
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.income),
                      // icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() {
                      _type = newSelection.first;
                      _categoryId = null; // Reset category on type change
                    });
                  },
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: WidgetStateProperty.all(BorderSide(
                      color: colorScheme.outlineVariant,
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Amount Input
              // Big, bold, colored
              IntrinsicWidth(
                child: TextFormField(
                  autofocus: widget.transaction == null,
                  initialValue: _amount?.toStringAsFixed(2),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: theme.textTheme.displayMedium?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                    hintText: '0.00',
                    hintStyle: theme.textTheme.displayMedium?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;
                      return (text.isEmpty ||
                              RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text))
                          ? newValue
                          : oldValue;
                    }),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) return l10n.required;
                    final p = double.tryParse(value);
                    if (p == null || p <= 0) return l10n.invalidAmount;
                    return null;
                  },
                  onSaved: (value) => _amount = double.parse(value!),
                ),
              ),
              const SizedBox(height: 32),

              const FeatherDivider(),
              const SizedBox(height: 16),

              // 3. Date & Time
              _FormRow(
                icon: Icons.access_time,
                child: InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          DateFormat.yMMMEd()
                              .format(_date), // e.g., Sat, Jan 20
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.jm().format(_date), // e.g., 5:08 PM
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 4. Category
              _FormRow(
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
                        return InkWell(
                          onTap: () async {
                            final result = await showModalBottomSheet<int>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => _SelectionSheet<dynamic>(
                                title: l10n.category,
                                options: filtered,
                                getLabel: (c) => c.name,
                                getIcon: (c) => IconData(
                                  int.tryParse(c.iconKey) ?? 0xe574,
                                  fontFamily: 'MaterialIcons',
                                ),
                                isSelected: (c) => c.id == state.value,
                                onSelected: (c) => Navigator.pop(context, c.id),
                              ),
                            );
                            if (result != null) {
                              state.didChange(result);
                              setState(() => _categoryId = result);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    if (selected != null) ...[
                                      Icon(
                                        IconData(
                                          int.tryParse(selected.iconKey) ??
                                              0xe574,
                                          fontFamily: 'MaterialIcons',
                                        ),
                                        size: 20,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Text(
                                      selected?.name ?? l10n.category,
                                      style: selected == null
                                          ? theme.textTheme.bodyLarge
                                              ?.copyWith(color: theme.hintColor)
                                          : theme.textTheme.bodyLarge,
                                    ),
                                    const Spacer(),
                                    Icon(Icons.chevron_right,
                                        color: theme.hintColor),
                                  ],
                                ),
                              ),
                              if (state.hasError)
                                Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
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
              _FormRow(
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
                        return InkWell(
                          onTap: () async {
                            final result = await showModalBottomSheet<int>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) => _SelectionSheet<dynamic>(
                                title: l10n.account,
                                options: accounts,
                                getLabel: (a) => a.name,
                                isSelected: (a) => a.id == state.value,
                                onSelected: (a) => Navigator.pop(context, a.id),
                              ),
                            );
                            if (result != null) {
                              state.didChange(result);
                              setState(() => _accountId = result);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      selected?.name ?? l10n.account,
                                      style: selected == null
                                          ? theme.textTheme.bodyLarge
                                              ?.copyWith(color: theme.hintColor)
                                          : theme.textTheme.bodyLarge,
                                    ),
                                    const Spacer(),
                                    Icon(Icons.chevron_right,
                                        color: theme.hintColor),
                                  ],
                                ),
                              ),
                              if (state.hasError)
                                Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
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
              _FormRow(
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

class _FormRow extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _FormRow({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, right: 24.0),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _SelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final String Function(T) getLabel;
  final IconData? Function(T)? getIcon;
  final bool Function(T) isSelected;
  final ValueChanged<T> onSelected;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.getLabel,
    required this.isSelected,
    required this.onSelected,
    this.getIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = isSelected(option);
                  final icon = getIcon?.call(option);

                  return ListTile(
                    leading: icon != null
                        ? Icon(
                            icon,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
                    title: Text(
                      getLabel(option),
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
