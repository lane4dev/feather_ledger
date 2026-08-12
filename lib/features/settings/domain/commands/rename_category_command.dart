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

/// Saves a category name and, when supplied, its appearance atomically.
class RenameCategoryCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  RenameCategoryCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    required String categoryId,
    required String name,
    String? iconKey,
    int? colorInt,
  }) async {
    if ((iconKey == null) != (colorInt == null)) {
      throw ArgumentError('Icon and color must be provided together');
    }
    if (!await _categoryExists(categoryId)) {
      throw CommandRejected(
          LedgerErrorCode.categoryNotFound, 'Category $categoryId not found');
    }

    final version = await nextStreamVersion(_eventStore, categoryId);
    final events = <LedgerEventPayload>[
      CategoryRenamed(categoryId: categoryId, name: name),
      if (iconKey != null && colorInt != null)
        CategoryAppearanceChanged(
            categoryId: categoryId, iconKey: iconKey, colorInt: colorInt),
    ];
    await _eventStore.append(
      [
        for (var i = 0; i < events.length; i++)
          envelopeFor(
            events[i],
            aggregateType: AggregateType.category,
            streamVersion: version + i,
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
