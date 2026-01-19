import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/database/tables.dart';
import 'package:feather_ledger/features/settings/presentation/providers/settings_providers.dart';

import '../providers/ledger_providers.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(ledgerSummaryProvider);
    final transactionsAsync = ref.watch(ledgerTransactionsProvider);
    final currency = ref.watch(currencyControllerProvider).valueOrNull ?? '\$';
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.ledgerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                // Show only month/year? Standard picker is fine for now.
              );
              if (picked != null) {
                ref.read(selectedDateProvider.notifier).setMonth(picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Month Navigation & Summary
          Card(
            margin: EdgeInsets.all(spacing.sm),
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          ref.read(selectedDateProvider.notifier).setMonth(
                                DateTime(
                                    selectedDate.year, selectedDate.month - 1),
                              );
                        },
                      ),
                      Text(
                        DateFormat.yMMMM().format(selectedDate),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          ref.read(selectedDateProvider.notifier).setMonth(
                                DateTime(
                                    selectedDate.year, selectedDate.month + 1),
                              );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  summaryAsync.when(
                    data: (summary) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                            label: l10n.income,
                            value: summary.totalIncome,
                            color: Colors.green,
                            currency: currency),
                        _SummaryItem(
                            label: l10n.expense,
                            value: summary.totalExpense,
                            color: Colors.red,
                            currency: currency),
                        _SummaryItem(
                            label: l10n.balance,
                            value: summary.runningBalance,
                            color: Colors.blue,
                            currency: currency),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text(l10n.errorPrefix(e.toString())),
                  ),
                ],
              ),
            ),
          ),

          // 2. Transaction List
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(child: Text(l10n.noTransactionsThisMonth));
                }

                // Group by date
                // Note: transactions should be ordered by date desc from DAO
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final showHeader = index == 0 ||
                        !DateUtils.isSameDay(
                            transactions[index - 1].date, tx.date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.md,
                              vertical: spacing.sm,
                            ),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            width: double.infinity,
                            child: Text(
                              DateFormat.yMMMd().format(tx.date),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(tx.category.colorInt),
                            child: Icon(
                                IconData(
                                    int.tryParse(tx.category.iconKey) ?? 0xe574,
                                    fontFamily: 'MaterialIcons'),
                                color: Colors.white,
                                size: 20),
                          ),
                          title: Text(tx.category.name),
                          subtitle: tx.note != null && tx.note!.isNotEmpty
                              ? Text(tx.note!)
                              : null,
                          trailing: Text(
                            '${tx.type == TransactionType.expense ? '-' : '+'} $currency${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: tx.type == TransactionType.expense
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text(l10n.errorPrefix(e.toString()))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/ledger/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String currency;

  const _SummaryItem(
      {required this.label,
      required this.value,
      required this.color,
      required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(
          '$currency${value.toStringAsFixed(2)}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
