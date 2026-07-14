import 'dart:convert';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_rebuild_service.dart';

import '../../../../support/event_sourcing/ledger_service_harness.dart';

/// The icons migration, end to end (CategoryCreated v1 → v2).
///
/// A category's icon is a **stored code point** and the projection is derived
/// from events, so the upgrade is not a code change someone can make and
/// forget: an existing ledger has to be *rebuilt* onto the new vocabulary,
/// through the upcaster, or its categories keep pointing at a font the app no
/// longer draws with. This plants a v1 event the way an older build wrote one
/// and checks where the rebuild lands.
void main() {
  late LedgerServiceHarness harness;

  setUp(() => harness = LedgerServiceHarness());
  tearDown(() => harness.close());

  /// Writes a `CategoryCreated` the way schema v1 wrote it — Material code
  /// point and all — rather than going through today's command, which would
  /// stamp v2 and defeat the point.
  Future<void> plantV1Category(String id, int materialCodePoint) async {
    await harness.db.into(harness.db.ledgerEvents).insert(
          LedgerEventsCompanion.insert(
            eventId: 'evt_$id',
            streamId: id,
            aggregateType: AggregateType.category,
            eventType: 'CategoryCreated',
            streamVersion: 1,
            occurredAt: DateTime(2026, 1, 1),
            recordedAt: DateTime(2026, 1, 1),
            commandId: 'cmd_$id',
            payload: jsonEncode({
              'schemaVersion': 1,
              'categoryId': id,
              'name': 'Food',
              'iconKey': '$materialCodePoint',
              'colorInt': 0xFF000000,
              'type': CategoryType.expense.name,
            }),
          ),
        );
  }

  test('a ledger written before the change rebuilds onto Lucide icons',
      () async {
    await plantV1Category('cat_food', Icons.restaurant.codePoint);

    await LedgerRebuildService(harness.db, harness.eventStore, harness.projector)
        .rebuild();

    final category = await harness.db.categoriesDao.getCategoryById('cat_food');
    expect(category!.iconKey, '${LucideIcons.utensils.codePoint}',
        reason: 'a rebuilt ledger must land on the icons a fresh one gets');
    expect(category.name, 'Food');
  });

  test('every icon the old palette offered survives the rebuild', () async {
    // One category per legacy entry, so a missing mapping is a category whose
    // face silently changes on upgrade rather than a table entry nobody read.
    final legacy = CategoryTokens.legacyIconCodePoints;
    var i = 0;
    for (final entry in legacy.entries) {
      await plantV1Category('cat_${i++}', entry.key);
    }

    await LedgerRebuildService(harness.db, harness.eventStore, harness.projector)
        .rebuild();

    i = 0;
    for (final entry in legacy.entries) {
      final category =
          await harness.db.categoriesDao.getCategoryById('cat_${i++}');
      expect(category!.iconKey, '${entry.value}',
          reason: 'legacy code point ${entry.key} changed its icon');
    }
  });
}
