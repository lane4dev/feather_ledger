import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/commands/delete_recurring_bill_command.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/recurring_view_model.dart';
import 'ledger_detail_row.dart';
import 'ledger_sheet_handle.dart';

/// What you can do with an upcoming recurring bill (spec 004, US2).
///
/// Deliberately not the transaction detail sheet: a pending bill has no event
/// stream to show and cannot be edited — the only honest actions are to record
/// it or delete it.
class PendingBillSheet extends ConsumerWidget {
  const PendingBillSheet({
    super.key,
    required this.transaction,
    this.currencySymbol,
  });

  final TransactionTileUiModel transaction;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currency =
        currencySymbol ?? AppCurrencies.defaultCurrency.symbol;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.spacing.lg,
        0,
        context.spacing.lg,
        context.spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSheetHandle(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.cancel,
              ),
            ],
          ),
          Text(
            '${transaction.displaySign} $currency${transaction.displayAmount}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: switch (transaction.type) {
                TransactionKind.expense => context.colors.expense,
                TransactionKind.income => context.colors.income,
                TransactionKind.transfer =>
                  Theme.of(context).colorScheme.onSurface,
              },
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.md),
          const FeatherDivider(),
          SizedBox(height: context.spacing.md),

          LedgerDetailRow(
            label: l10n.date,
            value: _formatDate(transaction.date),
          ),
          SizedBox(height: context.spacing.md),
          LedgerDetailRow(
            label: l10n.category,
            value: transaction.category.name,
          ),
          SizedBox(height: context.spacing.md),
          LedgerDetailRow(
            label: l10n.account,
            value: transaction.account.name,
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            SizedBox(height: context.spacing.md),
            LedgerDetailRow(label: l10n.note, value: transaction.note!),
          ],

          SizedBox(height: context.spacing.lg),
          FilledButton(
            onPressed: () => _post(context, ref, l10n),
            child: Text(l10n.postInstance),
          ),
          SizedBox(height: context.spacing.sm),
          OutlinedButton(
            onPressed: () => _delete(context, ref, l10n),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// Recording moves money, so it asks first.
  Future<void> _post(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.postInstanceTitle),
        content: Text(l10n.postInstanceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.postInstance),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref.read(recurringViewModelProvider.notifier).postInstance(
            transaction.id,
          ),
      success: l10n.instancePosted,
    );
  }

  /// Deleting asks how far it reaches first: the same gesture means "not this
  /// month" or "never again", and the difference is not recoverable.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final scope = await showDialog<RecurringDeleteScope>(
      context: context,
      builder: (context) => _DeleteScopeDialog(l10n: l10n),
    );
    if (scope == null || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .deleteBill(transaction.id, scope: scope),
      success: l10n.billDeleted,
    );
  }

  /// Runs a write, reports it, and closes the sheet on success — the one
  /// place a failure is rendered.
  Future<void> _run(
    BuildContext context,
    AppLocalizations l10n,
    Future<Result<void>> Function() action, {
    required String success,
  }) async {
    final result = await action();
    if (!context.mounted) return;

    if (result case Failure(:final code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(code.message(l10n))));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(success)));
  }

  static String _formatDate(DateTime date) => '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Picks how far a delete reaches. Pops the chosen [RecurringDeleteScope], or
/// null when cancelled.
class _DeleteScopeDialog extends StatefulWidget {
  const _DeleteScopeDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_DeleteScopeDialog> createState() => _DeleteScopeDialogState();
}

class _DeleteScopeDialogState extends State<_DeleteScopeDialog> {
  // The narrowest scope is the default: it is the only one that cannot take
  // a bill the user did not mean to touch.
  RecurringDeleteScope _scope = RecurringDeleteScope.thisOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.deleteRecurringTitle),
      content: RadioGroup<RecurringDeleteScope>(
        groupValue: _scope,
        onChanged: (value) => setState(() => _scope = value!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final scope in RecurringDeleteScope.values)
              RadioListTile<RecurringDeleteScope>(
                value: scope,
                contentPadding: EdgeInsets.zero,
                title: Text(_label(l10n, scope)),
                // Only the widest scope needs reassuring: it is the one that
                // reads as "throw the whole series away".
                subtitle: scope == RecurringDeleteScope.all
                    ? Text(l10n.deleteScopeAllHint)
                    : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _scope),
          child: Text(l10n.delete),
        ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, RecurringDeleteScope scope) =>
      switch (scope) {
        RecurringDeleteScope.thisOnly => l10n.deleteScopeThisOnly,
        RecurringDeleteScope.thisAndFollowing =>
          l10n.deleteScopeThisAndFollowing,
        RecurringDeleteScope.all => l10n.deleteScopeAll,
      };
}
