import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../../domain/entities/ledger_entities.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/recurring_view_model.dart';
import 'ledger_delete_menu.dart';
import 'ledger_receipt_content.dart';

/// What you can do with an upcoming recurring bill (spec 004, US2).
///
/// Deliberately not the transaction detail sheet: a pending bill has no event
/// stream to show. What it can do is be recorded, edited, or skipped/stopped
/// (or deleted for a one-off plan) — recording is the bottom button, and the
/// rest sit where a recorded transaction's sheet puts them: the pencil and
/// the overflow menu.
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
    final currency = currencySymbol ??
        AppCurrencies.getSymbol(transaction.account.currencyCode);
    final isPlanned = transaction.series?.mode == RecurringSeriesMode.planned;

    if (transaction.isSkipped) {
      return AppReceiptSheet(
        toolbar: const LedgerReceiptToolbar(
          showEdit: false,
          showDelete: false,
        ),
        footer: AppBottomActionBar(
          child: AppButton(
            onPressed: () => _restore(context, ref, l10n),
            child: Text(l10n.restoreToPending),
          ),
        ),
        child: LedgerReceiptContent(
          transaction: transaction,
          currencySymbol: currency,
          status: l10n.skippedBill,
        ),
      );
    }

    return AppReceiptSheet(
      toolbar: LedgerReceiptToolbar(
        onEdit: () => _edit(context),
        overflowActions: isPlanned
            ? [
                LedgerOverflowAction(
                  label: l10n.deletePlan,
                  icon: LucideIcons.trash2,
                  destructive: true,
                  onSelected: () => _deletePlan(context, ref, l10n),
                ),
              ]
            : [
                LedgerOverflowAction(
                  label: l10n.skipThisBill,
                  icon: LucideIcons.skipForward,
                  onSelected: () => _skipBill(context, ref, l10n),
                ),
                LedgerOverflowAction(
                  label: l10n.stopRepeatingRule,
                  icon: LucideIcons.circleOff,
                  destructive: true,
                  onSelected: () => _stopRepeating(context, ref, l10n),
                ),
              ],
      ),
      footer: AppBottomActionBar(
        child: AppButton(
          onPressed: () => _post(context, ref, l10n),
          child: Text(
              transaction.isFailed ? l10n.retryPost : l10n.postInstance),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (transaction.isFailed) ...[
            Container(
              padding: EdgeInsets.all(context.spacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: Text(
                      l10n.failedBillBanner,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.spacing.md),
          ],
          LedgerReceiptContent(
            transaction: transaction,
            currencySymbol: currency,
            status: transaction.isFailed ? l10n.failedBill : l10n.pendingBill,
          ),
        ],
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) =>
      _run(
        context,
        l10n,
        () => ref
            .read(recurringViewModelProvider.notifier)
            .restoreSkippedBill(transaction.id),
        success: l10n.billRestored,
      );

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
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton.text(
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

  Future<void> _skipBill(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.skipBillTitle),
        content: Text(l10n.skipBillConfirm),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.skipBillAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .deleteBill(transaction.id, scope: RecurringScope.thisOnly),
      success: l10n.billSkipped,
    );
  }

  Future<void> _stopRepeating(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.stopRepeatingTitle),
        content: Text(l10n.stopRepeatingConfirm),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton(
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.stopRepeatingAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .deleteBill(transaction.id, scope: RecurringScope.updateRule),
      success: l10n.repeatingStopped,
    );
  }

  Future<void> _deletePlan(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlanTitle),
        content: Text(l10n.deletePlanConfirm),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          AppButton(
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      l10n,
      () => ref
          .read(recurringViewModelProvider.notifier)
          .deleteBill(transaction.id, scope: RecurringScope.updateRule),
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
}
