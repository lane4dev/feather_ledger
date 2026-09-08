import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';
import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'create_category_command.g.dart';

/// Creates a category via `CategoryCreated` (spec 003, US3/T028). System
/// categories pass a fixed [categoryId] and [systemCode]; regular
/// categories get a generated id.
class CreateCategoryCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;

  CreateCategoryCommand(this._eventStore, this._projector);

  Future<void> execute({
    required String commandId,
    String? categoryId,
    required String name,
    required String iconKey,
    required int colorInt,
    required CategoryType type,
    String? systemCode,
  }) async {
    final event = CategoryCreated(
      categoryId: categoryId ?? const Uuid().v4(),
      name: name,
      iconKey: iconKey,
      colorInt: colorInt,
      type: type,
      systemCode: systemCode,
    );

    await _eventStore.append(
      [
        envelopeFor(
          event,
          aggregateType: AggregateType.category,
          streamVersion: 0,
          commandId: commandId,
          eventId: const Uuid().v4(),
        ),
      ],
      options: AppendOptions(apply: _projector.applyAll),
    );
  }
}

@riverpod
CreateCategoryCommand createCategoryCommand(Ref ref) {
  return CreateCategoryCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
  );
}
