import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

/// One balance event of an account inside one month.
class _MonthEvent {
  final int gsn;
  final String txId;
  final TransactionKind kind;
  final List<Posting> postings; // legs on this account

  _MonthEvent(this.gsn, this.txId, this.kind, this.postings);
}

/// Monthly snapshot maintainer (spec 003, US7/T052/T053).
///
/// Driven from inside the append transaction by [LedgerProjectorImpl] after
/// every balance-relevant event (AccountCreated, OpeningBalanceSet,
/// TransactionRecorded, TransactionReversed). For each affected account the
/// whole month chain is recomputed from the account's anchor month (its
/// earliest business month: creation, opening balance or first posting) to
/// the latest materialized month (max of today and the latest event month),
/// so empty months materialize and historical edits cascade forward by
/// construction — a correction of a January transaction rewrites January and
/// every following month's opening/closing chain.
///
/// Income/expense are signed posting impacts by kind; transfer legs land in
/// transferIn/Out (never income/expense, spec 红线). Reversed transactions
/// are excluded — original and reversal cancel out.
///
/// `eventSequenceFrom`/`eventSequenceTo` bracket the event GSNs the row's
/// current values were computed from: from = the account's first event,
/// to = the latest event affecting the account up to that month.
///
/// ponytail: a per-account refresh scans the whole event stream — spec
/// blesses correctness over performance at personal-ledger scale; narrow to
/// the affected GSN range if it ever matters.
class MonthlySnapshotProjectorImpl {
  final AppDatabase _db;
  final DomainClock _clock;

  MonthlySnapshotProjectorImpl(
    this._db, {
    DomainClock clock = const SystemClock(),
  }) : _clock = clock;

  /// Recomputes every snapshot row of [accountId] from its anchor month to
  /// the latest materialized month.
  Future<void> refreshAccount(String accountId) async {
    final account = await _db.accountDao.getAccountById(accountId);
    if (account == null) return;

    // One forward pass over the whole event stream (GSN order).
    final rows = await _db.eventsDao.getAll();
    (int, int)? anchorMonth;
    int? anchorGsn;
    var openingAmount = 0;
    final recorded = <(int, int), List<_MonthEvent>>{};
    final reversedTxIds = <String>{};
    final originalMonthOf = <String, (int, int)>{};
    final reversalGsns = <(int, int), List<int>>{};

    for (final row in rows) {
      switch (row.eventType) {
        case 'AccountCreated':
          final p = AccountCreated.fromJson(_payload(row));
          if (p.accountId != accountId) break;
          (anchorMonth, anchorGsn) =
              _adoptAnchor(anchorMonth, anchorGsn, row.id,
                  _monthOf(row.occurredAt));
        case 'OpeningBalanceSet':
          final p = OpeningBalanceSet.fromJson(_payload(row));
          if (p.accountId != accountId) break;
          openingAmount += p.amountMinor.abs();
          (anchorMonth, anchorGsn) =
              _adoptAnchor(anchorMonth, anchorGsn, row.id,
                  _monthOf(row.occurredAt));
        case 'TransactionRecorded':
          final p = TransactionRecorded.fromJson(_payload(row));
          final legs = p.postings
              .where((posting) => posting.accountId == accountId)
              .toList();
          if (legs.isEmpty) break;
          final month = _monthOf(p.occurredAt);
          originalMonthOf[p.transactionId] = month;
          recorded
              .putIfAbsent(month, () => [])
              .add(_MonthEvent(row.id, p.transactionId, p.kind, legs));
          (anchorMonth, anchorGsn) =
              _adoptAnchor(anchorMonth, anchorGsn, row.id, month);
        case 'TransactionReversed':
          final p = TransactionReversed.fromJson(_payload(row));
          reversedTxIds.add(p.originalTransactionId);
        default:
          break; // not balance-relevant
      }
    }

    // No events for this account (direct-seeded legacy rows): one empty
    // snapshot at the current month.
    anchorMonth ??= _monthOf(_clock.today());

    // Latest materialized month: today, or any later event month.
    var latest = _monthOf(_clock.today());
    for (final m in recorded.keys) {
      if (_compare(m, latest) > 0) latest = m;
    }

    // Reversal business month = the original's month (its GSN affects that
    // row's event bracket).
    for (final row in rows) {
      if (row.eventType != 'TransactionReversed') continue;
      final p = TransactionReversed.fromJson(_payload(row));
      final month = originalMonthOf[p.originalTransactionId];
      if (month != null) {
        reversalGsns.putIfAbsent(month, () => []).add(row.id);
      }
    }

    // Sequential walk: opening chains from the previous row's closing.
    var opening = openingAmount;
    final from = anchorGsn ?? 0;
    var to = from;
    var (year, month) = anchorMonth;
    while (true) {
      final monthEvents = recorded[(year, month)] ?? const [];
      final live = monthEvents
          .where((e) => !reversedTxIds.contains(e.txId))
          .toList();
      final reversalsHere = reversalGsns[(year, month)] ?? const [];

      var income = 0;
      var expense = 0;
      var transferIn = 0;
      var transferOut = 0;
      var net = 0;
      for (final e in live) {
        for (final posting in e.postings) {
          final impact = posting.signedImpact;
          net += impact;
          switch (e.kind) {
            case TransactionKind.income:
              income += impact;
            case TransactionKind.expense:
              expense += impact;
            case TransactionKind.transfer:
              if (posting.direction == PostingDirection.credit) {
                transferIn += posting.amountMinor;
              } else {
                transferOut -= posting.amountMinor;
              }
          }
        }
        to = max(to, e.gsn);
      }
      to = reversalsHere.fold(to, max);

      await _db.monthlySnapshotDao
          .upsert(MonthlyAccountBalanceSnapshotsCompanion.insert(
        accountId: accountId,
        currencyCode: account.currencyCode,
        year: year,
        month: month,
        openingBalanceMinor: opening,
        closingBalanceMinor: opening + net,
        incomeMinor: income,
        expenseMinor: expense,
        transferInMinor: transferIn,
        transferOutMinor: transferOut,
        netChangeMinor: net,
        transactionCount: live.length,
        eventSequenceFrom: from,
        eventSequenceTo: to,
        projectionVersion: const Value(ledgerProjectionVersion),
        updatedAt: Value(_clock.now()),
      ));

      if (_compare((year, month), latest) >= 0) break;
      opening += net;
      (year, month) = _nextMonth((year, month));
    }
  }

  /// Payload decoded through the upcaster, like the main projector (schema
  /// 演进: old rows may carry older schemaVersions).
  Map<String, dynamic> _payload(LedgerEventRow row) =>
      ledgerEventRegistry.upcast(row.eventType,
          (jsonDecode(row.payload) as Map).cast<String, dynamic>());

  static (int, int) _monthOf(DateTime d) => (d.year, d.month);

  static int _compare((int, int) a, (int, int) b) {
    if (a.$1 != b.$1) return a.$1 - b.$1;
    return a.$2 - b.$2;
  }

  static (int, int) _nextMonth((int, int) m) =>
      m.$2 == 12 ? (m.$1 + 1, 1) : (m.$1, m.$2 + 1);

  /// Returns the anchor (month, GSN) updated with an earlier month or a
  /// lower GSN.
  static ((int, int), int) _adoptAnchor((int, int)? anchorMonth,
      int? anchorGsn, int rowId, (int, int) month) {
    final m = anchorMonth == null || _compare(month, anchorMonth) < 0
        ? month
        : anchorMonth;
    final g = anchorGsn == null || rowId < anchorGsn ? rowId : anchorGsn;
    return (m, g);
  }
}
