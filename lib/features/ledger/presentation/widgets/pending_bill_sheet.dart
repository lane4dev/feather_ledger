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
                onPressed: () => _edit(context, ref, l10n),
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
      builder: (context) => _ScopeDialog(
        l10n: l10n,
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

  /// Editing asks the same question, and for a harder reason: the scope
  /// decides which fields the form can even offer, because a single instance
  /// row has nowhere to keep a category or an account.
  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final scope = await showDialog<RecurringScope>(
      context: context,
      builder: (context) => _ScopeDialog(
        l10n: l10n,
        title: l10n.editRecurringTitle,
        confirmLabel: l10n.nextStep,
      ),
    );
    if (scope == null || !context.mounted) return;

    // Read the router first: the sheet is about to leave the tree, so its
    // context is no longer something to navigate from.
    final router = GoRouter.of(context);
    Navigator.of(context).pop(); // the sheet, so the form is not stacked on it
    // Not awaited: this sheet is gone, and what the form does next is
    // the form's business.
    unawaited(router.push('/ledger/edit-bill', extra: (transaction, scope)));
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

/// Picks how far an edit or a delete reaches. Pops the chosen
/// [RecurringScope], or null when cancelled.
///
/// Both actions ask the same question with the same three answers — they name
/// how much of the series is affected, which is the one thing the user knows
/// and the row does not.
class _ScopeDialog extends StatefulWidget {
  const _ScopeDialog({
    required this.l10n,
    required this.title,
    required this.confirmLabel,
    this.destructive = false,
  });

  final AppLocalizations l10n;
  final String title;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_ScopeDialog> createState() => _ScopeDialogState();
}

class _ScopeDialogState extends State<_ScopeDialog> {
  // The narrowest scope is the default: it is the only one that cannot take
  // a bill the user did not mean to touch.
  RecurringScope _scope = RecurringScope.thisOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: RadioGroup<RecurringScope>(
        groupValue: _scope,
        onChanged: (value) => setState(() => _scope = value!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final scope in RecurringScope.values)
              RadioListTile<RecurringScope>(
                value: scope,
                contentPadding: EdgeInsets.zero,
                title: Text(_label(l10n, scope)),
                // Only the widest scope needs reassuring: it is the one that
                // reads as "throw the whole series away".
                subtitle: scope == RecurringScope.all
                    ? Text(l10n.scopeAllHint)
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
          // A destructive confirm wears the error colour a recorded
          // transaction's delete does; "next" is not destructive and does not.
          style: widget.destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, RecurringScope scope) =>
      switch (scope) {
        RecurringScope.thisOnly => l10n.scopeThisOnly,
        RecurringScope.thisAndFollowing =>
          l10n.scopeThisAndFollowing,
        RecurringScope.all => l10n.scopeAll,
      };
}
