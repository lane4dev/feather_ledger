import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../../domain/events/transaction_event.dart';
import '../../data/event_handlers/ledger_transaction_event_handler.dart';

part 'adjust_account_balance_command.g.dart';

class AdjustAccountBalanceCommand {
  final Uuid _uuid = const Uuid();
  final LedgerTransactionEventHandler _ledgerTransactionEventHandler;

  AdjustAccountBalanceCommand(
    this._ledgerTransactionEventHandler,
  );

  Future<void> execute({
    required String accountId,
    required double
        adjustmentAmount, // Positive for increase, negative for decrease
    required DateTime date,
    required String categoryId, // A default category for balance adjustments
    required String description,
    required String notes,
  }) async {
    final transactionId = _uuid.v4();
    final eventId = _uuid.v4();

    final amountCents = (adjustmentAmount.abs() * 100).round();
    final role = adjustmentAmount >= 0
        ? TransactionRole.inflow
        : TransactionRole.outflow;

    final event = TransactionPosted(
      eventId: eventId,
      occurredAt: date,
      recordedAt: DateTime.now(),
      transactionId: transactionId,
      description: description,
      categoryId: categoryId,
      notes: notes,
      legs: [
        TransactionLeg(
          accountId: accountId,
          amount: adjustmentAmount >= 0 ? amountCents : -amountCents,
          role: role,
        )
      ],
    );

    // await _eventRepository.appendEvent(event);
    await _ledgerTransactionEventHandler.handleEvent(event);
  }
}

@riverpod
AdjustAccountBalanceCommand adjustAccountBalanceCommand(Ref ref) {
  return AdjustAccountBalanceCommand(
      ref.watch(ledgerTransactionEventHandlerProvider));
}
