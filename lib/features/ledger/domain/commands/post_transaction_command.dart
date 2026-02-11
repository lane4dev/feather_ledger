import 'package:feather_ledger/features/ledger/data/event_handlers/ledger_transaction_event_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';

import '../../domain/events/transaction_event.dart';

part 'post_transaction_command.g.dart';

class PostTransactionCommand {
  final LedgerTransactionEventHandler _ledgerTransactionEventHandler;

  final Uuid _uuid = const Uuid();

  PostTransactionCommand(
    this._ledgerTransactionEventHandler,
  );

  Future<void> execute({
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
  }) async {
    final transactionId = _uuid.v4();
    final eventId = _uuid.v4();

    // Convert to minor units (cents)
    final amountCents = (amount * 100).round();
    final signedAmount =
        type == TransactionType.expense ? -amountCents : amountCents;
    final role = type == TransactionType.expense
        ? TransactionRole.outflow
        : TransactionRole.inflow;

    final event = TransactionPosted(
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

    await _ledgerTransactionEventHandler.handleEvent(event);
  }
}

@riverpod
PostTransactionCommand postTransactionCommand(Ref ref) {
  return PostTransactionCommand(
      ref.watch(ledgerTransactionEventHandlerProvider));
}
