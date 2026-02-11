import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/events/ledger_event.dart';
import 'package:feather_ledger/core/domain/events/account_event.dart';
import 'package:feather_ledger/core/data/repositories/account_repository.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/core/data/repositories/event_repository.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/ledger_repository.dart';
import '../../domain/entities/ledger_entities.dart';
import '../../domain/events/transaction_event.dart';

part 'ledger_transaction_event_handler.g.dart';

class LedgerTransactionEventHandler {
  final EventRepository _eventRepository;
  final LedgerRepository _ledgerRepository;
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;

  final Uuid _uuid = const Uuid();

  LedgerTransactionEventHandler(
    this._eventRepository,
    this._ledgerRepository,
    this._accountRepository,
    this._categoryRepository,
  );

  Future<void> handleEvent(LedgerEvent event) async {
    switch (event) {
      case TransactionPosted():
        await _handleTransactionPosted(event);
      case TransactionReversed():
        await _handleTransactionReversed(event);
      default:
        throw UnimplementedError(
            'Event handler not implemented for event type: ${event.runtimeType}');
    }
  }

  Future<void> _handleTransactionPosted(TransactionPosted event) async {
    final account =
        await _accountRepository.getAccount(event.legs.first.accountId);
    final category = await _categoryRepository.getCategory(event.categoryId);

    if (account == null || category == null) {
      throw Exception(
          'Account or Category not found for event: ${event.eventId}');
    }

    final eventSerialId = await _eventRepository.appendEvent(event);

    // Amount needs to be converted back to double from cents
    final amount = event.legs.first.amount;

    final transactionEntity = TransactionEntity(
      id: event.transactionId,
      amount: amount, // Store absolute amount, type determines sign
      type: amount > 0 ? TransactionType.income : TransactionType.expense,
      date: event.occurredAt,
      note: event.description,
      category: category,
      account: account,
      isReversed: false,
      eventId: eventSerialId,
    );
    await _ledgerRepository.insertOrUpdateTransaction(transactionEntity);

    // Additional logic like updating account balance can be added here
    final accountUpdatedEvent = AccountUpdated(
      eventId: _uuid.v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      accountId: account.id,
      name: account.name,
      type: account.type,
    );

    await _eventRepository.appendEvent(accountUpdatedEvent);

    final updatedAccount = AccountEntity(
      id: account.id,
      name: account.name,
      type: account.type,
      postedBalance: account.postedBalance + event.legs.first.amount,
      availableBalance: account.availableBalance + event.legs.first.amount,
      lastUpdatedEventId: eventSerialId,
    );

    await _accountRepository.updateAccount(updatedAccount);
  }

  Future<void> _handleTransactionReversed(TransactionReversed event) async {
    // get account and category info from original transaction
    final originalTransaction =
        await _ledgerRepository.getTransaction(event.originalTransactionId);

    if (originalTransaction == null) {
      throw Exception(
          'Original transaction not found for reversal: ${event.originalTransactionId}');
    }

    final account = originalTransaction
        .account; // Assuming single leg transactions for simplicity

    // 1. Append the reversal event first to get the serial ID
    final eventSerialId = await _eventRepository.appendEvent(event);

    // Additional logic like updating account balance can be added here
    final accountUpdatedEvent = AccountUpdated(
      eventId: _uuid.v4(),
      occurredAt: DateTime.now(),
      recordedAt: DateTime.now(),
      accountId: account.id,
      name: account.name,
      type: account.type,
    );
    await _eventRepository.appendEvent(accountUpdatedEvent);

    final updatedAccount = AccountEntity(
      id: account.id,
      name: account.name,
      type: account.type,
      postedBalance: account.postedBalance - originalTransaction.amount,
      availableBalance: account.availableBalance - originalTransaction.amount,
      lastUpdatedEventId: eventSerialId,
    );
    await _accountRepository.updateAccount(updatedAccount);

    await _ledgerRepository.deleteTransaction(event.originalTransactionId);
  }
}

@Riverpod(keepAlive: true)
LedgerTransactionEventHandler ledgerTransactionEventHandler(Ref ref) {
  return LedgerTransactionEventHandler(
    ref.watch(eventRepositoryProvider),
    ref.watch(ledgerRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
