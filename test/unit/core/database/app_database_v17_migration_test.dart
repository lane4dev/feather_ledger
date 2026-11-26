import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

void main() {
  test(
      'migrates v16 to v17: adds materialize_from (backfilled from start_date) '
      'and completed_count_offset (default 0), migrates repeating occurrence_key '
      'to local civil YYYY-MM-DD with conflict priority posted > failed > '
      'scheduled > skipped, keeps planned single key, and preserves '
      'event-sourced tables without bumping projection version', () async {
    final file = File(p.join(
      Directory.systemTemp.createTempSync('feather_v16').path,
      'v16.sqlite',
    ));

    // Seed a database at v16 schema.
    final v16 = AppDatabase.internal(NativeDatabase(file));
    await v16.customStatement('SELECT 1');

    // Drop v17 columns if present so the file truly starts at v16.
    final cols = (await v16
            .customSelect('PRAGMA table_info(recurring_series)')
            .get())
        .map((r) => r.read<String>('name'))
        .toSet();
    if (cols.contains('materialize_from')) {
      await v16.customStatement(
          'ALTER TABLE recurring_series DROP COLUMN materialize_from');
    }
    if (cols.contains('completed_count_offset')) {
      await v16.customStatement(
          'ALTER TABLE recurring_series DROP COLUMN completed_count_offset');
    }

    // Seed event-sourced tables at current ledgerProjectionVersion.
    await v16.customStatement(
      'INSERT INTO ledger_events '
      '(event_id, stream_id, aggregate_type, event_type, stream_version, '
      'occurred_at, recorded_at, command_id, payload) '
      "VALUES ('evt-1', 'acc-1', 0, 'AccountCreated', 1, 1780000000, 1780000000, 'cmd-1', '{}')",
    );
    await v16.customStatement(
      'INSERT INTO accounts_view '
      '(id, name, type, currency_code, balance_minor, archived, deleted, '
      'include_in_totals, last_updated_event_id, projection_version) '
      "VALUES ('acc-1', 'Cash', 0, 'CNY', 120000, 0, 0, 1, 1, $ledgerProjectionVersion)",
    );
    await v16.customStatement(
      'INSERT INTO categories_view '
      '(id, name, icon_key, color_int, type, archived, last_updated_event_id, projection_version) '
      "VALUES ('cat-1', 'Dining', 'utensils', ${0xFFE65100}, ${CategoryType.expense.index}, 0, 1, $ledgerProjectionVersion)",
    );

    final start1 = DateTime(2026, 11, 1, 0, 30);
    final start1Sec = start1.millisecondsSinceEpoch ~/ 1000;
    final planStart = DateTime(2026, 11, 10, 9, 0);
    final planStartSec = planStart.millisecondsSinceEpoch ~/ 1000;

    // Seed one repeating series and one planned series.
    await v16.customStatement(
      'INSERT INTO recurring_series '
      '(id, rrule, start_date, frequency, interval, amount_minor, description, '
      'category_id, account_id, type, auto_post, mode, is_active) '
      "VALUES ('s-rep', 'FREQ=DAILY', $start1Sec, 'DAILY', 1, 2500, 'Coffee', "
      "'cat-1', 'acc-1', ${RecurringSeriesKind.expense.index}, 0, ${RecurringSeriesMode.repeating.index}, 1)",
    );
    await v16.customStatement(
      'INSERT INTO recurring_series '
      '(id, rrule, start_date, end_date, frequency, interval, amount_minor, '
      'description, category_id, account_id, type, auto_post, mode, is_active) '
      "VALUES ('s-plan', 'FREQ=DAILY', $planStartSec, $planStartSec, 'DAILY', 1, 9000, 'One-off', "
      "'cat-1', 'acc-1', ${RecurringSeriesKind.expense.index}, 0, ${RecurringSeriesMode.planned.index}, 1)",
    );

    int sec(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

    // 1. Chain-shifted rows: old keys shifted by -1 day compared to local date.
    //    2026-10-31 -> 2026-11-01, 2026-11-01 -> 2026-11-02
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('chain-1', 's-rep', '2026-10-31', ${sec(DateTime(2026, 11, 1, 0, 30))}, 'scheduled', 0)",
    );
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('chain-2', 's-rep', '2026-11-01', ${sec(DateTime(2026, 11, 2, 0, 30))}, 'scheduled', 0)",
    );

    // 2. Conflict group A (all map to local 2026-11-05):
    //    posted must win over failed, scheduled, skipped.
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only, transaction_id) '
      "VALUES ('cA-skip', 's-rep', '2026-11-04', ${sec(DateTime(2026, 11, 5, 0, 10))}, 'skipped', 0, NULL)",
    );
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only, transaction_id) '
      "VALUES ('cA-post', 's-rep', '2026-11-05', ${sec(DateTime(2026, 11, 5, 9, 0))}, 'posted', 0, 'tx-posted')",
    );
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only, transaction_id) '
      "VALUES ('cA-fail', 's-rep', '2026-11-05-dup', ${sec(DateTime(2026, 11, 5, 10, 0))}, 'failed', 0, NULL)",
    );

    // 3. Conflict group B (all map to local 2026-11-06):
    //    failed must win over scheduled and skipped.
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('cB-sched', 's-rep', '2026-11-06-a', ${sec(DateTime(2026, 11, 6, 8, 0))}, 'scheduled', 0)",
    );
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('cB-fail', 's-rep', '2026-11-06-b', ${sec(DateTime(2026, 11, 6, 9, 0))}, 'failed', 0)",
    );

    // 4. Conflict group C (all map to local 2026-11-07):
    //    scheduled must win over skipped.
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('cC-skip', 's-rep', '2026-11-07-a', ${sec(DateTime(2026, 11, 7, 8, 0))}, 'skipped', 0)",
    );
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('cC-sched', 's-rep', '2026-11-07-b', ${sec(DateTime(2026, 11, 7, 9, 0))}, 'scheduled', 0)",
    );

    // 5. Planned row keeps 'single'.
    await v16.customStatement(
      'INSERT INTO scheduled_transactions_view '
      '(id, series_id, occurrence_key, scheduled_date, status, manual_only) '
      "VALUES ('plan-1', 's-plan', '$kPlannedOccurrenceKey', $planStartSec, 'scheduled', 0)",
    );

    await v16.customStatement('PRAGMA user_version = 16');
    await v16.close();

    // Re-open to trigger v16 -> v17 upgrade.
    final upgraded = AppDatabase.internal(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect(upgraded.schemaVersion, 17);

    // Verify new columns on recurring_series + backfill.
    final repSeries = await upgraded.recurringDao.getSeries('s-rep');
    expect(repSeries, isNotNull);
    expect(repSeries!.materializeFrom, repSeries.startDate);
    expect(repSeries.completedCountOffset, 0);

    final planSeries = await upgraded.recurringDao.getSeries('s-plan');
    expect(planSeries, isNotNull);
    expect(planSeries!.materializeFrom, planSeries.startDate);
    expect(planSeries.completedCountOffset, 0);

    // Verify repeating rows migrated and deduplicated by priority.
    final repRows = await upgraded.recurringDao.scheduledForSeries('s-rep');
    final byId = {for (final r in repRows) r.id: r};

    expect(byId.keys,
        unorderedEquals(['chain-1', 'chain-2', 'cA-post', 'cB-fail', 'cC-sched']));
    expect(byId['chain-1']!.occurrenceKey, '2026-11-01');
    expect(byId['chain-2']!.occurrenceKey, '2026-11-02');
    expect(byId['cA-post']!.occurrenceKey, '2026-11-05');
    expect(byId['cA-post']!.transactionId, 'tx-posted');
    expect(byId['cB-fail']!.occurrenceKey, '2026-11-06');
    expect(byId['cC-sched']!.occurrenceKey, '2026-11-07');

    // Verify planned row kept 'single'.
    final planRow = await upgraded.recurringDao.getScheduled('plan-1');
    expect(planRow, isNotNull);
    expect(planRow!.occurrenceKey, kPlannedOccurrenceKey);

    // Verify event-sourced tables untouched.
    final acc = await upgraded.accountDao.getAccountById('acc-1');
    expect(acc, isNotNull);
    expect(acc!.balanceMinor, 120000);
    expect(acc.projectionVersion, ledgerProjectionVersion);
    final events = await upgraded.select(upgraded.ledgerEvents).get();
    expect(events, hasLength(1));
  });
}
