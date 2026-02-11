import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';

class AccountSummaryCard extends ConsumerWidget {
  final String accountId;
  final String accountName;
  final bool isLiability;

  const AccountSummaryCard({
    super.key,
    required this.accountId,
    required this.accountName,
    required this.isLiability,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off loading once; the ViewModel caches results per accountId.
    ref.read(ledgerViewModelProvider.notifier).ensureAccountBalanceLoaded(
          accountId,
        );

    final ledgerState = ref.watch(ledgerViewModelProvider);
    final balanceAsync =
        ledgerState.accountBalances[accountId] ?? const AsyncLoading();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(accountName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            balanceAsync.when(
              data: (balance) {
                // Formatting: This logic assumes negative balance for Liability = Debt.
                // We display Debt as Positive number "Owed".
                final posted = balance.posted / 100.0;
                // available logic: If credit limit exists, available = limit + posted (since posted is negative).
                // But we don't know credit limit here unless passed or in Account entity.
                // For now just show "Balance" or "Owed".

                if (isLiability) {
                  return Column(
                    children: [
                      Text('Owed: \$${(-posted).abs().toStringAsFixed(2)}'),
                      // Available logic omitted as we don't have limit in AccountBalance yet
                    ],
                  );
                } else {
                  return Text('Balance: \$${posted.toStringAsFixed(2)}');
                }
              },
              loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => const Text('Error loading balance'),
            ),
          ],
        ),
      ),
    );
  }
}
