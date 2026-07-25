import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/constants/category_constants.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The balance-purpose migration, end to end — through a **rebuild**, which
/// is the only thing that can produce it.
///
/// Records written before balance purposes existed are ordinary income/expense
/// events filed under one of two fixed system category IDs, and nothing
/// rewrites those events. The *projector* interprets them instead, so what a
/// legacy row means is decided at replay time. Two consequences make this
/// worth its own test:
///
/// * The interpretation exists **only** in the projection, so a database that
///   migrates and never rebuilds still shows the old meaning. `ledgerProjectionVersion`
///   going to 4 is what forces the replay; this is the test that the replay
///   lands where it should.
/// * Every other test of this behaviour writes its "legacy" record with
///   **today's** command, which stamps the modern kind and only exercises the
///   new path. Planting a payload the old build actually wrote is the only way
///   to cover the branch that reads it.
///
/// See `category_icon_migration_test.dart` for the same shape applied to the
/// icon vocabulary.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  final occurredAt = DateTime(2026, 1, 5);

  /// Writes an `AccountCreated` as the pre-`includeInTotals` build wrote it:
  /// no such key, and none needed — the column default is the honest answer
  /// for an account that predates the flag.
  Future<void> plantLegacyAccount(String accountId) async {
    await harness.db.into(harness.db.ledgerEvents).insert(
          LedgerEventsCompanion.insert(
            eventId: 'evt_${accountId}_created',
            streamId: accountId,
            aggregateType: AggregateType.account,
            eventType: 'AccountCreated',
            streamVersion: 1,
            occurredAt: occurredAt,
            recordedAt: occurredAt,
            commandId: 'cmd_${accountId}_created',
            payload: jsonEncode({
              'schemaVersion': 1,
              'accountId': accountId,
              'name': 'Legacy cash',
              'type': AccountType.cash.name,
              'currencyCode': 'USD',
            }),
          ),
        );
  }

  /// Writes a `TransactionRecorded` the way the old build wrote a balance
  /// move: a plain income or expense row whose posting names a system
  /// reversal category. Deliberately *not* routed through today's command,
  /// which would stamp `openingBalance`/`balanceAdjustment` and leave the
  /// compatibility branch unread.
  Future<void> plantLegacyRecord({
    required String transactionId,
    required String commandId,
    required String accountId,
    required String categoryId,
    required TransactionKind kind,
    required PostingDirection direction,
    required int amountMinor,
  }) async {
    await harness.db.into(harness.db.ledgerEvents).insert(
          LedgerEventsCompanion.insert(
            eventId: 'evt_$transactionId',
            streamId: transactionId,
            aggregateType: AggregateType.transaction,
            eventType: 'TransactionRecorded',
            streamVersion: 1,
            occurredAt: occurredAt,
            recordedAt: occurredAt,
            commandId: commandId,
            payload: jsonEncode({
              'schemaVersion': 1,
              'transactionId': transactionId,
              'occurredAt': occurredAt.toIso8601String(),
              'kind': kind.name,
              'description': 'Initial balance for a new account.',
              'postings': [
                {
                  'accountId': accountId,
                  'direction': direction.name,
                  'amountMinor': amountMinor,
                  'currencyCode': 'USD',
                  'categoryId': categoryId,
                },
              ],
            }),
          ),
        );
  }

  Future<void> rebuild() => LedgerRebuildService(
        harness.db,
        harness.eventStore,
        harness.projector,
      ).rebuild();

  Future<TransactionViewRow> rowOf(String transactionId) async =>
      (await (harness.db.select(harness.db.transactionsView)
                ..where((t) => t.transactionId.equals(transactionId)))
              .getSingle());

  test('a legacy opening record replays as an opening balance, not income',
      () async {
    await plantLegacyAccount('acc_legacy');
    await plantLegacyRecord(
      transactionId: 'txn_opening',
      // The suffix is the whole signal: account creation derived it so the
      // pair would deduplicate together. Everything else filed under a
      // reversal category was a later adjustment.
      commandId: 'cmd_create_account-opening',
      accountId: 'acc_legacy',
      categoryId: CategoryConstants.reversalIncomeId,
      kind: TransactionKind.income,
      direction: PostingDirection.credit,
      amountMinor: 10000,
    );

    await rebuild();

    final row = await rowOf('txn_opening');
    expect(row.kind, TransactionKind.openingBalance);
    expect(row.categoryName, isNull,
        reason: 'the record stops wearing a category nobody could pick');
    expect(row.categoryIcon, isNull);
    expect(row.categoryColorInt, isNull);

    // The event itself is untouched — the interpretation lives in the
    // projection, because events are immutable and this is not a rewrite.
    final event = (await harness.eventStore.readAll())
        .events
        .firstWhere((e) => e.eventId == 'evt_txn_opening');
    expect(event.payloadJson['kind'], TransactionKind.income.name,
        reason: "the event's kind is history; the view's kind is the reading");

    // It moves the balance and nothing else. This is the half a
    // projection-only change gets wrong: `net` accumulates before the kind
    // switch, so the money lands in the balance and in no bucket.
    final account = await harness.db.accountDao.getAccountById('acc_legacy');
    expect(account!.balanceMinor, 10000);

    final january = await harness.db.monthlySnapshotDao
        .getForAccount('acc_legacy', 2026, 1);
    expect(january!.closingBalanceMinor, 10000);
    expect(january.incomeMinor, 0,
        reason: 'money that predates the book is not this month earnings');

    final header = await harness.ledgerService
        .watchMonthlySnapshot(DateTime(2026, 1), currencyCode: 'USD')
        .first;
    expect(header.incomeMinor, 0,
        reason: 'and the ledger totals agree with the snapshot');
    expect(header.balanceMinor, 10000);
  });

  test('a legacy adjustment record replays as a balance adjustment', () async {
    await plantLegacyAccount('acc_legacy');
    await plantLegacyRecord(
      transactionId: 'txn_adjust',
      // Minted, not derived — `adjustAccountBalance` never used the suffix,
      // which is what separates it from an opening record.
      commandId: 'e5f1c2a4-90f7-4c33-9a1e-2b7d6c8f0a11',
      accountId: 'acc_legacy',
      categoryId: CategoryConstants.reversalExpenseId,
      kind: TransactionKind.expense,
      direction: PostingDirection.debit,
      amountMinor: 2500,
    );

    await rebuild();

    final row = await rowOf('txn_adjust');
    expect(row.kind, TransactionKind.balanceAdjustment);
    expect(row.categoryName, isNull);

    final january = await harness.db.monthlySnapshotDao
        .getForAccount('acc_legacy', 2026, 1);
    expect(january!.closingBalanceMinor, -2500);
    expect(january.expenseMinor, 0,
        reason: 'reconciling a balance is not spending');
  });

  test('the meaning only exists after the replay', () async {
    // The property the version bump buys. Planted behind the projector's
    // back — which is what a database written by an older build looks like
    // from here — nothing has been interpreted yet; the rebuild is what
    // makes it true. Without `ledgerProjectionVersion` moving, a migrated
    // database would keep the old reading forever.
    await plantLegacyAccount('acc_legacy');
    await plantLegacyRecord(
      transactionId: 'txn_opening',
      commandId: 'cmd_create_account-opening',
      accountId: 'acc_legacy',
      categoryId: CategoryConstants.reversalIncomeId,
      kind: TransactionKind.income,
      direction: PostingDirection.credit,
      amountMinor: 10000,
    );

    expect(await harness.db.select(harness.db.transactionsView).get(), isEmpty,
        reason: 'the events are the only thing that exists so far');

    await rebuild();

    expect(await rowOf('txn_opening'), isNotNull);
  });
}
