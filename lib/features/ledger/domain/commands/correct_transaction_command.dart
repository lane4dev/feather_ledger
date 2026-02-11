import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../../data/event_handlers/ledger_transaction_event_handler.dart';
import '../../domain/events/transaction_event.dart';

part 'correct_transaction_command.g.dart';

class CorrectTransactionCommand {
  final LedgerTransactionEventHandler _ledgerTransactionEventHandler;

  final Uuid _uuid = const Uuid();

  CorrectTransactionCommand(
    this._ledgerTransactionEventHandler,
  );
  Future<void> execute({
    required String originalTransactionId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) async {
    // 1. Reverse original
    final reverseEvent = TransactionReversed(
      eventId: _uuid.v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      originalTransactionId: originalTransactionId,
      reason: 'Correction',
    );
    // await _eventRepository.appendEvent(reverseEvent);
    await _ledgerTransactionEventHandler.handleEvent(reverseEvent);

    // 2. Post new
    // Convert to minor units (cents)
    final amountCents = (amount * 100).round();
    final signedAmount =
        type == TransactionType.expense ? -amountCents : amountCents;
    final role = type == TransactionType.expense
        ? TransactionRole.outflow
        : TransactionRole.inflow;

    final transactionId = _uuid.v4();
    final eventId = _uuid.v4();

    final postEvent = TransactionPosted(
      eventId: eventId,
      occurredAt: date,
      recordedAt: DateTime.now(),
      transactionId: transactionId,
      description: note ?? '',
      categoryId: categoryId,
      notes: note,
      legs: [
        TransactionLeg(
          accountId: accountId,
          amount: signedAmount,
          role: role,
        )
      ],
    );
    // await _eventRepository.appendEvent(postEvent);
    await _ledgerTransactionEventHandler.handleEvent(postEvent);
  }
}

@riverpod
CorrectTransactionCommand correctTransactionCommand(Ref ref) {
  return CorrectTransactionCommand(
    ref.watch(ledgerTransactionEventHandlerProvider),
  );
}
