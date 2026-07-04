import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/recurring_view_model.dart';
import 'ledger_delete_menu.dart';
import 'ledger_detail_row.dart';
import 'ledger_sheet_handle.dart';
import 'recurring_scope_dialog.dart';

/// What you can do with an upcoming recurring bill (spec 004, US2).
///
/// Deliberately not the transaction detail sheet: a pending bill has no event
/// stream to show. What it can do is be recorded, edited, or deleted —
/// recording is the bottom button, and the other two sit where a recorded
/// transaction's sheet puts them, the pencil and the overflow menu.
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
              const Spacer(),
              // Edit and delete sit where a recorded transaction's sheet puts
              // them: the pencil beside the overflow menu.
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(context),
                tooltip: l10n.edit,
              ),
              LedgerDeleteMenu(onDelete: () => _delete(context, ref, l10n)),
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
    final scope = await showDialog<RecurringScope>(
      context: context,
      builder: (context) => RecurringScopeDialog(
        title: l10n.deleteRecurringTitle,
        confirmLabel: l10n.delete,
        destructive: true,
      ),
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

  /// Editing opens the form straight away. How far the change reaches is
  /// asked when it is saved, because that is when there is something to reach
  /// with — and because a field the chosen scope cannot keep only becomes a
  /// question once the user has touched it.
  void _edit(BuildContext context) {
    // Read the router first: the sheet is about to leave the tree, so its
    // context is no longer something to navigate from.
    final router = GoRouter.of(context);
    Navigator.of(context).pop(); // the sheet, so the form is not stacked on it
    // Not awaited: this sheet is gone, and what the form does next is
    // the form's business.
    unawaited(router.push('/ledger/edit-bill', extra: transaction));
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
