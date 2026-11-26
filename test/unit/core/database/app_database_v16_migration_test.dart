import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:feather_ledger/app/bootstrap/register_ledger_events.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

void main() {
  setUpAll(registerLedgerEvents);

  test(
      'migrates v15 to v16 preserving historical rows, adding budget tables, '
      'and self-healing categories_view.archived_at on rebuild', () async {
    final file = File(p.join(
      Directory.systemTemp.createTempSync('feather_v15').path,
      'v15.sqlite',
    ));
    final v15 = AppDatabase.internal(NativeDatabase(file));
    await v15.customStatement('SELECT 1');
    await v15.customStatement(
        'ALTER TABLE categories_view DROP COLUMN archived_at');
    await v15.customStatement(
        'ALTER TABLE recurring_series DROP COLUMN materialize_from');
    await v15.customStatement(
        'ALTER TABLE recurring_series DROP COLUMN completed_count_offset');
    await v15.customStatement('DROP TABLE IF EXISTS budget_rules');
    await v15.customStatement('DROP TABLE IF EXISTS budget_review_notes');

    final createdAt = DateTime(2026, 2, 10, 12, 0);
    final archivedAt = DateTime(2026, 4, 30, 23, 30);

    await v15.into(v15.ledgerEvents).insert(
          LedgerEventsCompanion.insert(
            eventId: 'evt-cat-1',
            streamId: 'cat-dining',
            aggregateType: AggregateType.category,
            eventType: 'CategoryCreated',
            streamVersion: 1,
            occurredAt: createdAt,
            recordedAt: createdAt,
            commandId: 'cmd-cat-1',
            payload: jsonEncode({
              'schemaVersion': 2,
              'categoryId': 'cat-dining',
              'name': 'Dining',
              'iconKey': 'utensils',
              'colorInt': 0xFFE65100,
              'type': CategoryType.expense.name,
            }),
          ),
        );
    await v15.into(v15.ledgerEvents).insert(
          LedgerEventsCompanion.insert(
            eventId: 'evt-cat-2',
            streamId: 'cat-dining',
            aggregateType: AggregateType.category,
            eventType: 'CategoryArchived',
            streamVersion: 2,
            occurredAt: archivedAt,
            recordedAt: archivedAt,
            commandId: 'cmd-cat-2',
            payload: jsonEncode({
              'schemaVersion': 1,
              'categoryId': 'cat-dining',
            }),
          ),
        );

    await v15.customStatement(
      'INSERT INTO categories_view '
      '(id, name, icon_key, color_int, type, archived, last_updated_event_id, projection_version) '
      "VALUES ('cat-dining', 'Dining', 'utensils', ${0xFFE65100}, ${CategoryType.expense.index}, 1, 2, 7)",
    );
    await v15.customStatement('PRAGMA user_version = 15');
    await v15.close();

    final upgraded = AppDatabase.internal(NativeDatabase(file));
    addTearDown(upgraded.close);

    expect(upgraded.schemaVersion, 17);

    final tables = (await upgraded
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get())
        .map((r) => r.read<String>('name'))
        .toSet();
    expect(tables, containsAll(['budget_rules', 'budget_review_notes']));

    final catBeforeRebuild =
        await upgraded.categoriesDao.getCategoryById('cat-dining');
    expect(catBeforeRebuild, isNotNull);
    expect(catBeforeRebuild!.archived, isTrue);
    expect(catBeforeRebuild.archivedAt, isNull);
    expect(catBeforeRebuild.projectionVersion, 7);

    final eventStore = DriftEventStore(upgraded, ledgerEventRegistry);
    final projector = LedgerProjectorImpl(upgraded);
    final rebuild = LedgerRebuildService(upgraded, eventStore, projector);

    expect(await rebuild.isStale(), isTrue);
    await rebuild.rebuild();
    expect(await rebuild.isStale(), isFalse);

    final catAfterRebuild =
        await upgraded.categoriesDao.getCategoryById('cat-dining');
    expect(catAfterRebuild, isNotNull);
    expect(catAfterRebuild!.archived, isTrue);
    expect(catAfterRebuild.archivedAt, isNotNull);
    expect(catAfterRebuild.archivedAt!.year, 2026);
    expect(catAfterRebuild.archivedAt!.month, 4);
    expect(catAfterRebuild.projectionVersion, ledgerProjectionVersion);
  });
}
