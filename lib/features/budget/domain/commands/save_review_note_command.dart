import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../value_objects/budget_value_objects.dart';

part 'save_review_note_command.g.dart';

class SaveReviewNoteCommand {
  static const int maxLength = 500;

  final BudgetRepository _repository;
  final DomainClock _clock;

  SaveReviewNoteCommand(
    this._repository, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  Future<void> execute({
    required String currencyCode,
    required YearMonth month,
    String? categoryId,
    required String note,
  }) async {
    final trimmed = note.trim();
    if (trimmed.runes.length > maxLength) {
      throw const CommandRejected(
        LedgerErrorCode.budgetNoteTooLong,
        'Review note cannot exceed 500 characters.',
      );
    }

    if (categoryId != null) {
      final category = await _repository.getCategoryById(categoryId);
      if (category == null) {
        throw CommandRejected(
          LedgerErrorCode.categoryNotFound,
          'Category $categoryId does not exist.',
        );
      }
      if (category.systemCode != null) {
        throw CommandRejected(
          LedgerErrorCode.systemCategoryProtected,
          'System category $categoryId cannot hold a review note.',
        );
      }
      if (category.archived) {
        throw CommandRejected(
          LedgerErrorCode.categoryArchived,
          'Archived category $categoryId review notes are read-only.',
        );
      }
      if (category.type != CategoryType.expense) {
        throw const CommandRejected(
          LedgerErrorCode.categoryTypeMismatch,
          'Only expense categories support budget review notes.',
        );
      }
    }

    await _repository.upsertReviewNote(
      currencyCode: currencyCode,
      month: month,
      categoryId: categoryId,
      note: trimmed,
      now: _clock.now(),
    );
  }
}

@riverpod
SaveReviewNoteCommand saveReviewNoteCommand(Ref ref) {
  return SaveReviewNoteCommand(ref.watch(budgetRepositoryProvider));
}
