import 'dart:async';

import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/router/app_router.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/notifications/recurring_reminders.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/presentation/mappers/transaction_ui_mapper.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/show_transaction_detail_sheet.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles foreground and cold-start notification responses after navigation is ready.
class ReminderResponseHandler extends ConsumerStatefulWidget {
  const ReminderResponseHandler({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ReminderResponseHandler> createState() =>
      _ReminderResponseHandlerState();
}

class _ReminderResponseHandlerState
    extends ConsumerState<ReminderResponseHandler> {
  StreamSubscription<void>? _subscription;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    final reminders = ref.read(recurringRemindersProvider);
    _subscription = reminders.responsesChanged.listen((_) => _drain());
    WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _drain() async {
    if (!mounted || _handling) return;
    final navigator =
        ref.read(goRouterProvider).routerDelegate.navigatorKey.currentState;
    if (navigator?.overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
      return;
    }
    _handling = true;
    try {
      final reminders = ref.read(recurringRemindersProvider);
      while (mounted) {
        final responses = reminders.takeResponses();
        if (responses.isEmpty) break;
        for (final response in responses) {
          if (!mounted) break;
          try {
            await _handle(response);
          } catch (error) {
            // Never auto-post a subscription after its notification action
            // failed: the requested skip or post may not have taken effect.
            if (response.actionId == RecurringReminders.skipAction ||
                response.actionId == RecurringReminders.postAction) {
              reminders.takeDeferredAutoPostCatchUp();
            }
            debugPrint('Reminder response failed: $error');
            final navContext = ref
                .read(goRouterProvider)
                .routerDelegate
                .navigatorKey
                .currentState
                ?.overlay
                ?.context;
            if (navContext != null && navContext.mounted) {
              final l10n = AppLocalizations.of(navContext)!;
              ScaffoldMessenger.maybeOf(navContext)?.showSnackBar(SnackBar(
                  content: Text(LedgerErrorCode.unknownEvent.message(l10n))));
            }
          } finally {
            await _finishDeferredAutoPost();
          }
        }
      }
    } finally {
      _handling = false;
    }
  }

  Future<void> _finishDeferredAutoPost() async {
    if (!mounted ||
        !ref.read(recurringRemindersProvider).takeDeferredAutoPostCatchUp()) {
      return;
    }
    try {
      final result = await ref
          .read(recurringServiceProvider)
          .catchUpAutoPostedWithSummary();
      if (mounted && result.circuitBreakerTripped) {
        ref
            .read(overdueMaterializationNoticeProvider.notifier)
            .setCircuitBreakerLatched(result.circuitBreakerLatchedCount);
      }
    } catch (error) {
      debugPrint('Deferred recurring auto-post failed: $error');
    }
  }

  Future<void> _handle(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null ||
        !payload.startsWith(RecurringReminders.payloadPrefix)) {
      return;
    }
    final id = payload.substring(RecurringReminders.payloadPrefix.length);
    if (id.isEmpty) return;
    final action = response.actionId;
    if (action != null &&
        action.isNotEmpty &&
        action != RecurringReminders.postAction &&
        action != RecurringReminders.skipAction) {
      return;
    }

    if (action == null || action.isEmpty) await _finishDeferredAutoPost();
    if (!mounted) return;
    final bill = await _resolveScheduled(id);
    if (!mounted) return;
    final service = ref.read(recurringServiceProvider);
    final navigator =
        ref.read(goRouterProvider).routerDelegate.navigatorKey.currentState;
    final navContext = navigator?.overlay?.context;
    if (navContext == null || !navContext.mounted) return;
    final l10n = AppLocalizations.of(navContext)!;
    void message(String text) => ScaffoldMessenger.maybeOf(navContext)
        ?.showSnackBar(SnackBar(content: Text(text)));

    if (bill == null) {
      message(l10n.notificationUnavailable);
      return;
    }
    if (action == RecurringReminders.skipAction ||
        action == RecurringReminders.postAction) {
      if (bill.status != ScheduledTransactionStatus.scheduled) {
        message(l10n.notificationUnavailable);
        return;
      }
      final result = action == RecurringReminders.postAction
          ? await service.postInstance(bill.id, commandId: 'notification-post-${bill.id}')
          : await service.deleteBill(bill.id, scope: RecurringScope.thisOnly);
      if (!mounted || !navContext.mounted) return;
      if (result case Failure(:final code)) {
        // Keep the bill pending when the action failed; startup catch-up is
        // retried on the next launch instead of undoing the user's intent.
        ref.read(recurringRemindersProvider).takeDeferredAutoPostCatchUp();
        message(code.message(l10n));
        return;
      }
      await _finishDeferredAutoPost();
      if (!mounted || !navContext.mounted) return;
      if (action == RecurringReminders.skipAction) {
        message(l10n.notificationSkipped);
        return;
      }
      message(l10n.instancePosted);
      final updated = (await service.watchScheduled().first)
          .where((item) => item.id == bill.id)
          .firstOrNull;
      if (updated == null || !mounted || !navContext.mounted) return;
      await _showRecorded(updated, navContext);
      return;
    }

    if (bill.status == ScheduledTransactionStatus.posted) {
      await _showRecorded(bill, navContext);
      return;
    }
    if ((bill.status != ScheduledTransactionStatus.scheduled &&
            bill.status != ScheduledTransactionStatus.failed &&
            bill.status != ScheduledTransactionStatus.skipped) ||
        bill.account == null ||
        bill.category == null) {
      message(l10n.notificationUnavailable);
      return;
    }
    final tile = const TransactionUiMapper()
        .toPendingTile(bill, account: bill.account!, category: bill.category!);
    final ledgerContext = await _openLedger();
    if (ledgerContext == null || !ledgerContext.mounted) return;
    await showAppReceiptSheet(
        context: ledgerContext,
        builder: (_) => PendingBillSheet(transaction: tile));
  }

  Future<ScheduledTransactionEntity?> _resolveScheduled(String id) async {
    final bill = await ref.read(recurringServiceProvider).getScheduled(id);
    if (bill == null) return null;
    if (bill.status == ScheduledTransactionStatus.scheduled ||
        bill.status == ScheduledTransactionStatus.posted ||
        bill.status == ScheduledTransactionStatus.failed ||
        bill.status == ScheduledTransactionStatus.skipped) {
      return bill;
    }
    return null;
  }

  Future<void> _showRecorded(
      ScheduledTransactionEntity bill, BuildContext navContext) async {
    final service = ref.read(ledgerServiceProvider);
    // The event-backed source-bill link names the latest correction (US47);
    // a posted bill resolves through it alone — the old redirect chain's
    // `transaction_id` fallback is gone with the table.
    final transaction = await service.getTransactionBySourceBill(bill.id);
    if (!mounted || !navContext.mounted) return;
    if (transaction == null) {
      final l10n = AppLocalizations.of(navContext)!;
      ScaffoldMessenger.maybeOf(navContext)
          ?.showSnackBar(SnackBar(content: Text(l10n.notificationDeleted)));
      return;
    }
    final ledgerContext = await _openLedger();
    if (ledgerContext == null || !ledgerContext.mounted) return;
    await showTransactionDetailSheet(
        context: ledgerContext,
        ref: ref,
        transaction: const TransactionUiMapper().toTile(transaction));
  }

  /// Let GoRouter finish replacing the current route before opening a sheet;
  /// otherwise that route change removes the sheet opened over it.
  Future<BuildContext?> _openLedger() async {
    ref.read(goRouterProvider).go('/ledger');
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final context = ref
        .read(goRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentState
        ?.overlay
        ?.context;
    return context != null && context.mounted ? context : null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
