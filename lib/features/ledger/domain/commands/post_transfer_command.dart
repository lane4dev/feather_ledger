import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/data/repositories/event_repository.dart';

import '../../domain/events/transaction_event.dart';

part 'post_transfer_command.g.dart';

class PostTransferCommand {
  final EventRepository _repository;
  final Uuid _uuid = const Uuid();

  PostTransferCommand(this._repository);

  Future<void> execute({
    required double amount,
    required DateTime date,
    required String fromAccountId,
    required String toAccountId,
    required String categoryId,
    String? note,
  }) async {
    final transactionId = _uuid.v4();
    final eventId = _uuid.v4();

    final amountCents = (amount * 100).round();

    final event = TransactionPosted(
      eventId: eventId,
      occurredAt: date,
      recordedAt: DateTime.now(),
      transactionId: transactionId,
      description: note ?? 'Transfer',
      categoryId: categoryId,
      notes: note,
      legs: [
        TransactionLeg(
          accountId: fromAccountId,
          amount: -amountCents,
          role: TransactionRole.outflow,
        ),
        TransactionLeg(
          accountId: toAccountId,
          amount: amountCents,
          role: TransactionRole.inflow,
        ),
      ],
    );

    await _repository.appendEvent(event);
  }
}

@riverpod
PostTransferCommand postTransferCommand(Ref ref) {
  return PostTransferCommand(ref.watch(eventRepositoryProvider));
}
