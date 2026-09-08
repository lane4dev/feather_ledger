import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

import '../../../../../support/fakes/fake_app_database.dart';

/// Contract test for the spec EventStore against an in-memory Drift database
/// (spec 003, US2/T023). Covers envelope round-trip, production factory
/// registration, commandId idempotency, stream version conflicts, GSN
/// ordering and unknown-event hard failure.
void main() {
  late FakeAppDatabase db;
  late EventStore store;

  setUp(() {
    db = FakeAppDatabase();
    registerLedgerEvents();
    store = DriftEventStore(db, ledgerEventRegistry);
  });

  tearDown(() => db.close());

  EventEnvelope envelope({
    String eventId = 'evt-1',
    String streamId = 'txn-1',
    AggregateType aggregateType = AggregateType.transaction,
    String eventType = 'TransactionRecorded',
    int streamVersion = 0,
    String commandId = 'cmd-1',
    Map<String, dynamic>? payload,
  }) =>
      EventEnvelope(
        eventId: eventId,
        streamId: streamId,
        aggregateType: aggregateType,
        eventType: eventType,
        streamVersion: streamVersion,
        payloadJson: payload ?? _recordedPayload(streamId),
        occurredAt: DateTime(2026, 1, 15),
        recordedAt: DateTime(2026, 1, 15),
        commandId: commandId,
      );

  group('append + readAll round-trip', () {
    test('persisted envelope is semantically equal and carries a GSN',
        () async {
      final original = envelope();

      final persisted = await store.append([original]);

      expect(persisted.single.globalSequenceNumber, 1);
      expect(persisted.single.eventId, original.eventId);

      final read = (await store.readAll()).events.single;
      expect(read.eventId, original.eventId);
      expect(read.streamId, original.streamId);
      expect(read.aggregateType, original.aggregateType);
      expect(read.eventType, original.eventType);
      expect(read.streamVersion, original.streamVersion);
      expect(read.commandId, original.commandId);
      expect(read.occurredAt, original.occurredAt);
      expect(read.recordedAt, original.recordedAt);
      expect(read.payloadJson, original.payloadJson);

      // JSON round-trip of the envelope itself
      final viaJson = EventEnvelope.fromJson(read.toJson());
      expect(viaJson.eventId, original.eventId);
      expect(viaJson.payloadJson, original.payloadJson);
    });
  });

  group('production factory registration (T021)', () {
    test('all nine final payloads are registered and readable', () {
      final registry = store.registry;
      const nine = [
        'TransactionRecorded',
        'TransactionReversed',
        'AccountCreated',
        'AccountRenamed',
        'AccountArchived',
        'CategoryCreated',
        'CategoryRenamed',
        'CategoryArchived',
        'OpeningBalanceSet',
      ];
      for (final type in nine) {
        expect(registry.hasFactory(type), isTrue,
            reason: 'production registration must cover "$type"');
      }
    });

    test('registered payloads upcast (no-op at v1) without throwing', () {
      final registry = store.registry;
      expect(
        registry.upcast('TransactionRecorded', _recordedPayload('txn-1')),
        _recordedPayload('txn-1'),
      );
    });

    test('unknown eventType hard-fails with the event id context', () {
      expect(
        () => store.registry.upcast('MysteryEvent', {'schemaVersion': 1}),
        throwsA(isA<UnknownEventTypeError>()),
      );
    });
  });

  group('commandId idempotency', () {
    test('duplicate commandId short-circuits and appends nothing', () async {
      await store.append([envelope(commandId: 'cmd-dup')]);

      await expectLater(
        store.append([envelope(eventId: 'evt-2', commandId: 'cmd-dup')]),
        throwsA(isA<DuplicateCommandError>()),
      );

      final all = (await store.readAll()).events;
      expect(all, hasLength(1));
      expect(all.single.eventId, 'evt-1');
    });

    test('commandExists reports previously appended ids', () async {
      expect(await store.commandExists('cmd-1'), isFalse);
      await store.append([envelope()]);
      expect(await store.commandExists('cmd-1'), isTrue);
    });
  });

  group('stream version conflicts', () {
    test('same (streamId, streamVersion) is rejected and rolls back',
        () async {
      await store.append([envelope()]);

      await expectLater(
        store.append([
          envelope(eventId: 'evt-2', streamVersion: 0, commandId: 'cmd-2')
        ]),
        throwsA(isA<StreamVersionConflictError>()),
      );

      final all = (await store.readAll()).events;
      expect(all, hasLength(1));
    });

    test('sequential versions on one stream are accepted', () async {
      await store.append([envelope()]);
      await store.append(
          [envelope(eventId: 'evt-2', streamVersion: 1, commandId: 'cmd-2')]);

      final stream = await store.readStream('txn-1');
      expect(stream.map((e) => e.streamVersion), [0, 1]);
      expect(stream.map((e) => e.eventId), ['evt-1', 'evt-2']);
    });

    test('a batch failing on any envelope rolls back the whole batch',
        () async {
      await store.append([envelope()]);

      await expectLater(
        store.append([
          envelope(eventId: 'evt-2', streamId: 'txn-2', commandId: 'cmd-2'),
          envelope(eventId: 'evt-3', streamVersion: 0, commandId: 'cmd-2'),
        ]),
        throwsA(isA<StreamVersionConflictError>()),
      );

      // The batch is all-or-nothing: evt-2 must not have been persisted.
      expect((await store.readAll()).events, hasLength(1));
    });
  });

  group('GSN ordering', () {
    test('GSNs are assigned monotonically in append order', () async {
      await store.append([envelope(eventId: 'e1', commandId: 'cmd-1')]);
      await store.append(
          [envelope(eventId: 'e2', streamId: 'txn-2', commandId: 'cmd-2')]);
      final batch = await store.append([
        envelope(eventId: 'e3', streamId: 'txn-3', commandId: 'cmd-3'),
        envelope(eventId: 'e4', streamId: 'txn-4', commandId: 'cmd-4'),
      ]);

      expect(batch.map((e) => e.globalSequenceNumber), [3, 4]);
      final all = (await store.readAll()).events;
      expect(all.map((e) => e.globalSequenceNumber), [1, 2, 3, 4]);
      expect(all.map((e) => e.eventId), ['e1', 'e2', 'e3', 'e4']);
    });

    test('readAll pages by GSN with nextAfter', () async {
      await store.append([envelope(eventId: 'e1', commandId: 'cmd-1')]);
      await store.append(
          [envelope(eventId: 'e2', streamId: 'txn-2', commandId: 'cmd-2')]);
      await store.append(
          [envelope(eventId: 'e3', streamId: 'txn-3', commandId: 'cmd-3')]);

      final first = await store.readAll(limit: 2);
      expect(first.events.map((e) => e.eventId), ['e1', 'e2']);
      expect(first.nextAfter, 2);

      final second = await store.readAll(after: first.nextAfter);
      expect(second.events.map((e) => e.eventId), ['e3']);
      expect(second.nextAfter, isNull);
    });

    test('readMaxGlobalSequenceNumber tracks the latest append', () async {
      expect(await store.readMaxGlobalSequenceNumber(), isNull);
      await store.append([envelope()]);
      expect(await store.readMaxGlobalSequenceNumber(), 1);
      await store.append([
        envelope(eventId: 'e2', streamId: 'txn-2', commandId: 'cmd-2')
      ]);
      expect(await store.readMaxGlobalSequenceNumber(), 2);
    });
  });

  group('append with projector hook', () {
    test('apply receives persisted envelopes and runs atomically', () async {
      var applyGsn = 0;
      final persisted = await store.append(
        [envelope()],
        options: AppendOptions(apply: (events) async {
          applyGsn = events.single.globalSequenceNumber!;
        }),
      );
      expect(persisted.single.globalSequenceNumber, applyGsn);
    });

    test('a throwing apply rolls the append back', () async {
      await expectLater(
        store.append(
          [envelope()],
          options: AppendOptions(apply: (events) async {
            throw StateError('projection exploded');
          }),
        ),
        throwsStateError,
      );

      expect((await store.readAll()).events, isEmpty,
          reason: 'failed projection must not leave the event persisted');
    });
  });
}

Map<String, dynamic> _recordedPayload(String transactionId) =>
    TransactionRecorded(
      transactionId: transactionId,
      occurredAt: DateTime(2026, 1, 15),
      kind: TransactionKind.expense,
      description: 'Lunch',
      postings: const [
        Posting(
          accountId: 'acc-1',
          direction: PostingDirection.debit,
          amountMinor: 1050,
          currencyCode: 'USD',
        ),
      ],
    ).toJson();
