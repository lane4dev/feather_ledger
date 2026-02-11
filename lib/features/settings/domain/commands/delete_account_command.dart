import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/repositories/event_repository.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';

import '../../../../core/domain/events/account_event.dart';

part 'delete_account_command.g.dart';

class DeleteAccountCommand {
  final EventRepository _eventRepository;
  final AccountRepository _accountRepository;

  DeleteAccountCommand(this._eventRepository, this._accountRepository);

  Future<void> execute(String accountId) async {
    final event = AccountDeleted(
      eventId: const Uuid().v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      accountId: accountId,
    );

    await _eventRepository.appendEvent(event);

    // Update read model
    await _accountRepository.deleteAccountProjection(accountId);
  }
}

@riverpod
DeleteAccountCommand deleteAccountCommand(Ref ref) {
  return DeleteAccountCommand(
    ref.watch(eventRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
}
