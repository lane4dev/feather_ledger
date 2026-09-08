import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/event_sourcing/event_envelope.dart';
import 'package:feather_ledger/core/domain/event_sourcing/event_store.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/data/repositories/category_repository.dart';
import 'package:feather_ledger/features/ledger/data/event_sourcing/drift_event_store.dart';

import 'package:feather_ledger/features/ledger/data/projections/ledger_projector.dart';
import 'package:feather_ledger/features/ledger/domain/events/ledger_events.dart';
import 'package:feather_ledger/features/ledger/domain/projections/ledger_projection.dart';

part 'archive_category_command.g.dart';

/// Archives a category via `CategoryArchived` (spec 003, US3/T028) — soft
/// delete; history keeps the row. Built-in system categories are rejected:
/// they must survive for balance adjustments.
class ArchiveCategoryCommand {
  final EventStore _eventStore;
  final LedgerProjector _projector;
  final CategoryRepository _categoryRepository;

  ArchiveCategoryCommand(this._eventStore, this._projector,
      this._categoryRepository);

  Future<void> execute({
    required String commandId,
    required String categoryId,
  }) async {
    final category = await _categoryRepository.getCategory(categoryId);
    if (category == null) {
      throw CommandRejected(
          LedgerErrorCode.categoryNotFound, 'Category $categoryId not found');
    }
    if (category.systemCode != null) {
      throw CommandRejected(LedgerErrorCode.systemCategoryProtected,
          'Category $categoryId is a built-in system category');
    }

    final event = CategoryArchived(categoryId: categoryId);
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
}

@riverpod
ArchiveCategoryCommand archiveCategoryCommand(Ref ref) {
  return ArchiveCategoryCommand(
    ref.watch(driftEventStoreProvider),
    ref.watch(ledgerProjectorProvider),
    ref.watch(categoryRepositoryProvider),
  );
}
