import 'package:feather_ledger/core/data/repositories/event_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/domain/events/transaction_event.dart';

part 'reverse_transaction_command.g.dart';

class ReverseTransactionCommand {
  final EventRepository _eventRepository;
  final Uuid _uuid = const Uuid();

  ReverseTransactionCommand(this._eventRepository);

  Future<void> execute(String originalTransactionId, String reason) async {
    final event = TransactionReversed(
      eventId: _uuid.v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      originalTransactionId: originalTransactionId,
      reason: reason,
    );

    await _eventRepository.appendEvent(event);
  }
}

@riverpod
ReverseTransactionCommand reverseTransactionCommand(Ref ref) {
  return ReverseTransactionCommand(ref.watch(eventRepositoryProvider));
}
