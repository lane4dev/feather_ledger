import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/data/transaction_attachment_store.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';

import '../models/transaction_tile_ui_model.dart';
import 'transaction_form_view_state.dart';

part 'transaction_form_view_model.g.dart';

/// How a save ended.
///
/// The view model never touches a snackbar, a dialog or a route: it says what
/// happened and the screen decides how to say it. Three cases, because the
/// fourth question — "this will overdraw the account, continue?" — is asked
/// *before* the write, not after it, and lives as [wouldOverdraft].
sealed class TransactionFormOutcome {
  const TransactionFormOutcome();
}

/// Recorded. A series, if one was asked for, exists.
final class TransactionFormSaved extends TransactionFormOutcome {
  const TransactionFormSaved();
}

/// Recorded, but the series could not be started. The money moved and the
/// schedule did not: reported separately, and the form still closes.
final class TransactionFormSavedSeriesFailed extends TransactionFormOutcome {
  final LedgerErrorCode code;

  const TransactionFormSavedSeriesFailed(this.code);
}

/// Nothing was recorded, and anything imported on the way has been discarded.
final class TransactionFormSaveFailed extends TransactionFormOutcome {
  final LedgerErrorCode code;

  const TransactionFormSaveFailed(this.code);
}

/// The form's state and the rules that read it.
///
/// The entry being corrected is the provider's *argument*, not something
/// seeded afterwards: a notifier may not modify a provider from `initState`,
/// and a form that filled itself in on the next frame would flash empty first.
/// The argument never changes while the form is open, which is the difference
/// between this family and the one [SearchViewModel] argues against — that one
/// took the query, which changes on every keystroke.
///
/// [build] deliberately watches nothing else. Watching the account or category
/// lists here would look harmless and be the opposite: every emission of those
/// streams re-runs `build` and wipes a half-filled form. The rules that need
/// those lists — which accounts a picker may offer, where a transfer may land
/// — are pure methods on [TransactionFormViewState], fed by the screen, which
/// watches those providers anyway.
///
/// Known ceiling: the family key is the tile itself, which has no `==`, so two
/// forms opened for "a new entry" at the same time would share one state.
/// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
/// push each other — and the fix, if something ever can, is a nested
/// `ProviderScope` per form.
@riverpod
class TransactionFormViewModel extends _$TransactionFormViewModel {
  @override
  TransactionFormViewState build(TransactionTileUiModel? original) =>
      original == null
          ? TransactionFormViewState.initial()
          : TransactionFormViewState.fromTile(original);

  void setAmountText(String text) => state = state.copyWith(amountText: text);

  void setNote(String note) => state = state.copyWith(note: note);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setRepeat(String frequency) => state = state.copyWith(repeat: frequency);

  void selectCategory(String id) => state = state.copyWith(categoryId: id);

  void selectToAccount(String id) => state = state.copyWith(toAccountId: id);

  /// Switching kind clears what the new kind cannot carry, rather than leaving
  /// a value in a field it does not render.
  void setType(TransactionKind type) {
    if (type == state.type) return;
    state = state.copyWith(type: type, categoryId: null, toAccountId: null);
  }

  /// The destination is keyed on the source — its candidates are filtered by
  /// the source's currency — so re-keying drops a choice the filter may no
  /// longer offer.
  void selectAccount(String id) =>
      state = state.copyWith(accountId: id, toAccountId: null);

  void attachFiles(List<XFile> files) => state = state.copyWith(
        pendingAttachments: [...state.pendingAttachments, ...files],
      );

  void removeAttachmentAt(int index) => state = state.copyWith(
        attachments: [
          ...state.attachments.take(index),
          ...state.attachments.skip(index + 1),
        ],
      );

  void removePendingAt(int index) => state = state.copyWith(
        pendingAttachments: [
          ...state.pendingAttachments.take(index),
          ...state.pendingAttachments.skip(index + 1),
        ],
      );

  /// Whether recording this entry would take its account below zero. The rule
  /// is the aggregate's ([AccountEntity.wouldOverdraft], which exempts credit
  /// accounts); whether to *ask* is the screen's.
  ///
  /// Only an expense is checked. A transfer's debit leg is the same question,
  /// but its semantics are genuinely ambiguous when both legs are the user's
  /// own money, so it is left alone until that is decided.
  bool wouldOverdraft() {
    final amount = state.amountMinor;
    if (state.type != TransactionKind.expense ||
        state.accountId == null ||
        amount == null) {
      return false;
    }
    final account = ref
        .read(accountListProvider)
        .value
        ?.where((a) => a.id == state.accountId)
        .firstOrNull;
    return account != null && account.wouldOverdraft(amount);
  }

  /// Records or corrects the entry, and starts its series if one was asked
  /// for. The screen validates the form first; this re-checks the amount so
  /// that a caller which skipped validation cannot reach a command with junk.
  Future<TransactionFormOutcome> submit() async {
    final form = state;
    final amountMinor = form.amountMinor;
    if (amountMinor == null) {
      return const TransactionFormSaveFailed(LedgerErrorCode.invalidAmount);
    }

    final imported = await _importPending();
    if (imported case Failure(:final code)) {
      return TransactionFormSaveFailed(code);
    }
    final attachments = [...form.attachments, ...imported.value];

    final ledger = ref.read(ledgerServiceProvider);
    final original = form.original;
    final result = switch (form.type) {
      TransactionKind.transfer => original == null
          ? ledger.addTransfer(
              commandId: const Uuid().v4(),
              amountMinor: amountMinor,
              fromAccountId: form.accountId!,
              toAccountId: form.toAccountId!,
              date: form.date,
              note: form.note,
              attachments: attachments,
            )
          : ledger.updateTransfer(
              commandId: const Uuid().v4(),
              id: original.id,
              amountMinor: amountMinor,
              fromAccountId: form.accountId!,
              toAccountId: form.toAccountId!,
              date: form.date,
              note: form.note,
              attachments: attachments,
            ),
      TransactionKind.openingBalance || TransactionKind.balanceAdjustment =>
        ledger.updateBalancePurpose(
          commandId: const Uuid().v4(),
          id: original!.id,
          // The sign in the field *is* the direction of this entry — a balance
          // purpose has no kind to carry one. [amountMinor] is signed here.
          signedAmountMinor: amountMinor,
          date: form.date,
          accountId: original.account.id,
          note: form.note,
          attachments: attachments,
        ),
      _ => original == null
          ? ledger.addTransaction(
              commandId: const Uuid().v4(),
              amountMinor: amountMinor,
              type: form.type,
              date: form.date,
              categoryId: form.categoryId!,
              accountId: form.accountId!,
              note: form.note,
              attachments: attachments,
            )
          : ledger.updateTransaction(
              commandId: const Uuid().v4(),
              id: original.id,
              amountMinor: amountMinor,
              type: form.type,
              date: form.date,
              categoryId: form.categoryId!,
              accountId: form.accountId!,
              note: form.note,
              attachments: attachments,
            ),
    };

    if (await result case Failure(:final code)) {
      // The files are in app storage and nothing refers to them, so a rejected
      // save takes them with it.
      await _discard(imported.value);
      return TransactionFormSaveFailed(code);
    }

    // Only once the money is recorded. If this fails the entry stands — it is a
    // real movement either way, and unwinding it because a schedule could not
    // be created would destroy a correct record to tidy up a separate one.
    if (!form.canRepeat || form.repeat == TransactionFormViewState.repeatNever) {
      return const TransactionFormSaved();
    }
    final series = await _startSeries(form, amountMinor);
    return switch (series) {
      Failure(:final code) => TransactionFormSavedSeriesFailed(code),
      Success() => const TransactionFormSaved(),
    };
  }

  /// Moves picked files into app-private storage before the entry refers to
  /// them. Nothing is imported until the user saves, so cancelling the form
  /// leaves nothing behind.
  Future<Result<List<TransactionAttachment>>> _importPending() async {
    final files = state.pendingAttachments;
    if (files.isEmpty) return const Success(<TransactionAttachment>[]);
    return guard(
        () => ref.read(transactionAttachmentStoreProvider).importFiles(files));
  }

  Future<void> _discard(List<TransactionAttachment> attachments) async {
    if (attachments.isEmpty) return;
    await ref.read(transactionAttachmentStoreProvider).discard(attachments);
  }

  /// Turns the entry into a series as well.
  ///
  /// Created after the transaction, and a failure here is not rolled back —
  /// see [submit].
  Future<Result<void>> _startSeries(
    TransactionFormViewState form,
    int amountMinor,
  ) {
    final categories = ref.read(categoryListProvider(form.categoryType)).value;
    final categoryName =
        categories?.where((c) => c.id == form.categoryId).firstOrNull?.name ??
            '';

    return ref.read(recurringServiceProvider).createSeries(
          type: form.type == TransactionKind.income
              ? RecurringSeriesKind.income
              : RecurringSeriesKind.expense,
          amountMinor: amountMinor,
          accountId: form.accountId!,
          categoryId: form.categoryId!,
          // A series must be named — the ledger list shows this. The note is
          // what the user called it; failing that, the category.
          description: form.note.trim().isEmpty
              ? categoryName
              : form.note.trim(),
          frequency: form.repeat,
          // The form's repeat row has no interval control: every rule is
          // "every one".
          interval: 1,
          startDate: nextOccurrence(form.date, form.repeat),
        );
  }

  /// The first occurrence *after* the one being recorded — the entry the user
  /// is making now is the current period, so the series picks up from the next
  /// and the two never overlap.
  ///
  /// Calendar arithmetic, so 31 Jan rolls to 28/29 Feb rather than spilling
  /// into March.
  static DateTime nextOccurrence(DateTime from, String frequency) =>
      switch (frequency) {
        'DAILY' => DateTime(from.year, from.month, from.day + 1),
        'WEEKLY' => DateTime(from.year, from.month, from.day + 7),
        'YEARLY' => DateTime(from.year + 1, from.month, from.day),
        _ => DateTime(from.year, from.month + 1, from.day),
      };
}
