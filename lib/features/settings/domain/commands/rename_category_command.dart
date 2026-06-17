import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';

import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'rename_category_command.g.dart';

/// Renames a category via `CategoryRenamed` (spec 003, US3/T028).
class RenameCategoryCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  RenameCategoryCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    required String categoryId,
    required String name,
  }) async {
    if (!await _categoryExists(categoryId)) {
      throw CommandRejected(
          LedgerErrorCode.categoryNotFound, 'Category $categoryId not found');
    }

    final event = CategoryRenamed(categoryId: categoryId, name: name);
    await _eventStore.append(
      [
        envelopeFor(
          event,
          aggregateType: AggregateType.category,
          streamVersion: await nextStreamVersion(_eventStore, categoryId),
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: _projector.applyAll),
    );
  }

  Future<bool> _categoryExists(String categoryId) async =>
      (await _eventStore.readStream(categoryId)).isNotEmpty;
}

@riverpod
RenameCategoryCommand renameCategoryCommand(Ref ref) {
  return RenameCategoryCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
