import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/event_repository.dart';

import '../../../../core/domain/events/account_event.dart';

part 'update_account_command.g.dart';

class UpdateAccountCommand {
  final EventRepository _eventRepository;
  final AccountRepository _accountRepository;

  UpdateAccountCommand(this._eventRepository, this._accountRepository);

  Future<void> execute({
    required String accountId,
    required String name,
    required AccountType type,
  }) async {
    final event = AccountUpdated(
      eventId: const Uuid().v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      accountId: accountId,
      name: name,
      type: type,
    );

    await _eventRepository.appendEvent(event);

    // Update read model
    final existingAccount = await _accountRepository.getAccount(accountId);
    if (existingAccount != null) {
      await _accountRepository.updateAccount(AccountEntity(
        id: event.accountId,
        name: event.name!,
        type: event.type!,
        postedBalance: existingAccount.postedBalance, // Keep existing balance
        availableBalance:
            existingAccount.availableBalance, // Keep existing balance
        // Temporarily using 0 for lastUpdatedEventId.
        lastUpdatedEventId: 0,
      ));
    }
  }
}

@riverpod
UpdateAccountCommand updateAccountCommand(Ref ref) {
  return UpdateAccountCommand(
    ref.watch(eventRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
}
