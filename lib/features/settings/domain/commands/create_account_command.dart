import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/event_repository.dart';

import '../../../../core/domain/events/account_event.dart';

part 'create_account_command.g.dart';

class CreateAccountCommand {
  final EventRepository _eventRepository;
  final AccountRepository _accountRepository;

  CreateAccountCommand(this._eventRepository, this._accountRepository);

  Future<void> execute({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    final accountId = const Uuid().v4();
    final event = AccountCreated(
      eventId: const Uuid().v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      accountId: accountId,
      name: name,
      type: type,
      initialBalance: (initialBalance * 100).toInt(),
    );

    await _eventRepository.appendEvent(event);

    // Update read model
    await _accountRepository.addAccount(AccountEntity(
      id: event.accountId,
      name: event.name,
      type: event.type,
      postedBalance: event.initialBalance,
      availableBalance: event.initialBalance,
      // Temporarily using 0 for lastUpdatedEventId.
      // This should ideally be the GSN from the event store.
      // This needs further clarification on how to get GSN from EventRepository.
      lastUpdatedEventId: 0,
    ));
  }
}

@riverpod
CreateAccountCommand createAccountCommand(Ref ref) {
  return CreateAccountCommand(
    ref.watch(eventRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
}
