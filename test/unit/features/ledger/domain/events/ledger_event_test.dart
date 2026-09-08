import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_type_registry.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

void main() {
  group('Transaction + Posting invariants', () {
    const posting = Posting(
      accountId: 'acc-1',
      direction: PostingDirection.debit,
      amountMinor: 1050,
      currencyCode: 'USD',
    );

    test('valid single-leg expense', () {
      final txn = Transaction(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        description: 'Lunch',
        kind: TransactionKind.expense,
        postings: [posting],
      );
      expect(txn.validate(), isNull);
    });

    test('income must be a single credit posting', () {
      final wrongDirection = Transaction(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        description: 'Salary',
        kind: TransactionKind.income,
        postings: [posting],
      );
      expect(wrongDirection.validate(), 'posting-direction');

      final twoLegs = Transaction(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        description: 'Salary',
        kind: TransactionKind.income,
        postings: [posting, posting],
      );
      expect(twoLegs.validate(), 'posting-count');
    });

    test('empty postings and non-positive amounts are rejected', () {
      final empty = Transaction(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        description: 'x',
        kind: TransactionKind.expense,
        postings: const [],
      );
      expect(empty.validate(), 'postings-empty');

      final zero = Transaction(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15),
        description: 'x',
        kind: TransactionKind.expense,
        postings: const [
          Posting(
            accountId: 'acc-1',
            direction: PostingDirection.debit,
            amountMinor: 0,
            currencyCode: 'USD',
          ),
        ],
      );
      expect(zero.validate(), 'amount-not-positive');
    });

    test('transfer requires opposite, equal, distinct, same-currency legs',
        () {
      Posting debit(String acc) => Posting(
            accountId: acc,
            direction: PostingDirection.debit,
            amountMinor: 10000,
            currencyCode: 'USD',
          );
      Posting credit(String acc) => Posting(
            accountId: acc,
            direction: PostingDirection.credit,
            amountMinor: 10000,
            currencyCode: 'USD',
          );

      Transaction transfer(List<Posting> postings) => Transaction(
            transactionId: 'txn-1',
            occurredAt: DateTime(2026, 1, 15),
            description: 'Move',
            kind: TransactionKind.transfer,
            postings: postings,
          );

      expect(transfer([debit('a'), credit('b')]).validate(), isNull);
      expect(transfer([debit('a'), credit('a')]).validate(),
          'transfer-same-account');
      expect(
        transfer([
          debit('a'),
          const Posting(
            accountId: 'b',
            direction: PostingDirection.credit,
            amountMinor: 9999,
            currencyCode: 'USD',
          ),
        ]).validate(),
        'transfer-amounts',
      );
      expect(transfer([debit('a'), debit('b')]).validate(),
          'transfer-directions');
      expect(
        transfer([
          debit('a'),
          const Posting(
            accountId: 'b',
            direction: PostingDirection.credit,
            amountMinor: 10000,
            currencyCode: 'CNY',
          ),
        ]).validate(),
        'transfer-currency',
      );
      expect(transfer([debit('a')]).validate(), 'posting-count');
    });

    test('signedImpact derives sign from direction only', () {
      expect(posting.signedImpact, -1050);
      const credit = Posting(
        accountId: 'acc-1',
        direction: PostingDirection.credit,
        amountMinor: 1050,
        currencyCode: 'USD',
      );
      expect(credit.signedImpact, 1050);
    });
  });

  group('final event payloads', () {
    test('TransactionRecorded round-trips with schemaVersion and postings',
        () {
      final event = TransactionRecorded(
        transactionId: 'txn-1',
        occurredAt: DateTime(2026, 1, 15, 8, 30),
        kind: TransactionKind.transfer,
        description: 'Move',
        notes: 'rent',
        postings: const [
          Posting(
            accountId: 'a',
            direction: PostingDirection.debit,
            amountMinor: 10000,
            currencyCode: 'USD',
            categoryId: null,
          ),
          Posting(
            accountId: 'b',
            direction: PostingDirection.credit,
            amountMinor: 10000,
            currencyCode: 'USD',
            memo: 'rent',
          ),
        ],
      );

      final restored = TransactionRecorded.fromJson(event.toJson());

      expect(restored.eventType, 'TransactionRecorded');
      expect(restored.streamId, 'txn-1');
      expect(restored.kind, TransactionKind.transfer);
      expect(restored.postings, hasLength(2));
      expect(restored.postings.first.signedImpact, -10000);
      expect(restored.postings.last.memo, 'rent');
      expect(event.toJson()['schemaVersion'], 1);
    });

    test('every payload serializes with stable eventType == class name', () {
      final events = <LedgerEventPayload>[
        TransactionRecorded(
            transactionId: 't',
            occurredAt: DateTime(2026),
            kind: TransactionKind.income,
            description: 'd',
            postings: const [
              Posting(
                  accountId: 'a',
                  direction: PostingDirection.credit,
                  amountMinor: 1,
                  currencyCode: 'USD'),
            ]),
        TransactionReversed(
            originalTransactionId: 't', reason: ReversalReason.correction),
        AccountCreated(
            accountId: 'a', name: 'n', type: AccountType.bank, currencyCode: 'USD'),
        AccountRenamed(accountId: 'a', name: 'n2'),
        AccountArchived(accountId: 'a'),
        CategoryCreated(
            categoryId: 'c',
            name: 'n',
            iconKey: 'i',
            colorInt: 0,
            type: CategoryType.expense,
            systemCode: 'sys'),
        CategoryRenamed(categoryId: 'c', name: 'n2'),
        CategoryArchived(categoryId: 'c'),
        OpeningBalanceSet(
            accountId: 'a', amountMinor: 100000, currencyCode: 'USD'),
      ];

      final expectedNames = {
        'TransactionRecorded',
        'TransactionReversed',
        'AccountCreated',
        'AccountRenamed',
        'AccountArchived',
        'CategoryCreated',
        'CategoryRenamed',
        'CategoryArchived',
        'OpeningBalanceSet',
      };

      expect(events.map((e) => e.eventType).toSet(), expectedNames);
      for (final e in events) {
        expect(e.toJson()['schemaVersion'], 1,
            reason: '${e.eventType} must embed schemaVersion');
      }
    });

    test('AccountCreated payload carries no initial balance', () {
      final event = AccountCreated(
          accountId: 'a', name: 'n', type: AccountType.cash, currencyCode: 'USD');
      expect(event.toJson().containsKey('initialBalance'), isFalse);
    });
  });

  group('EventEnvelope', () {
    EventEnvelope envelope({int? gsn}) => EventEnvelope(
          eventId: 'evt-1',
          streamId: 'txn-1',
          aggregateType: AggregateType.transaction,
          eventType: 'TransactionRecorded',
          streamVersion: 0,
          globalSequenceNumber: gsn,
          payloadJson: const {
            'schemaVersion': 1,
            'transactionId': 'txn-1',
          },
          occurredAt: DateTime(2026, 1, 15),
          recordedAt: DateTime(2026, 1, 16),
          commandId: 'cmd-1',
        );

    test('round-trips through JSON', () {
      final restored = EventEnvelope.fromJson(envelope(gsn: 7).toJson());
      expect(restored.eventType, 'TransactionRecorded');
      expect(restored.streamId, 'txn-1');
      expect(restored.streamVersion, 0);
      expect(restored.globalSequenceNumber, 7);
      expect(restored.commandId, 'cmd-1');
      expect(restored.payloadJson['schemaVersion'], 1);
    });

    test('withGlobalSequenceNumber copies and assigns GSN', () {
      final original = envelope();
      expect(original.globalSequenceNumber, isNull);
      final persisted = original.withGlobalSequenceNumber(3);
      expect(persisted.globalSequenceNumber, 3);
      expect(persisted.eventId, original.eventId);
      expect(original.globalSequenceNumber, isNull,
          reason: 'envelopes are immutable');
    });

    test('equality is by eventId', () {
      expect(envelope(gsn: 1), envelope(gsn: 2));
    });
  });

  group('EventTypeRegistry', () {
    EventTypeRegistry registry() => EventTypeRegistry()
      ..registerFactory(
          eventType: 'TransactionRecorded', factory: _identityFactory);

    test('upcast is a no-op when payload is at latest version', () {
      final r = registry();
      final payload = r.upcast(
          'TransactionRecorded', {'schemaVersion': 1, 'x': 1});
      expect(payload, {'schemaVersion': 1, 'x': 1});
    });

    test('steps through upcasters version by version', () {
      final r = registry()
        ..registerUpcaster(
          eventType: 'TransactionRecorded',
          fromVersion: 1,
          upcaster: (p) => {...p, 'schemaVersion': 2, 'addedInV2': true},
        )
        ..registerUpcaster(
          eventType: 'TransactionRecorded',
          fromVersion: 2,
          upcaster: (p) => {...p, 'schemaVersion': 3},
        );

      final payload = r.upcast('TransactionRecorded', {'schemaVersion': 1});
      expect(payload['schemaVersion'], 3);
      expect(payload['addedInV2'], isTrue);
    });

    test('default schemaVersion is 1 when absent', () {
      final r = registry()
        ..registerUpcaster(
          eventType: 'TransactionRecorded',
          fromVersion: 1,
          upcaster: (p) => {...p, 'schemaVersion': 2},
        );

      final payload = r.upcast('TransactionRecorded', {'x': 1});
      expect(payload['schemaVersion'], 2);
    });

    test('upcaster that does not advance schemaVersion throws', () {
      final r = registry()
        ..registerUpcaster(
          eventType: 'TransactionRecorded',
          fromVersion: 1,
          upcaster: (p) => p,
        );

      expect(
        () => r.upcast('TransactionRecorded', {'schemaVersion': 1}),
        throwsStateError,
      );
    });

    test('unknown eventType hard-fails', () {
      final r = registry();
      expect(
        () => r.upcast('MysteryEvent', {'schemaVersion': 1}),
        throwsA(isA<UnknownEventTypeError>()),
      );
    });

    test('duplicate factory registration throws', () {
      final r = registry();
      expect(
        () => r.registerFactory(
            eventType: 'TransactionRecorded', factory: _identityFactory),
        throwsStateError,
      );
    });
  });
}

Map<String, dynamic> _identityFactory(Map<String, dynamic> json) => json;
