import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/data/transaction_attachment_store.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';

import '../models/transaction_tile_ui_model.dart';
import '../models/custom_recurrence.dart';
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
          ? TransactionFormViewState.initial(
              // The form locks its currency at open time (spec 006, US21): a
              // one-time read, not a watch, so a later setting change cannot
              // re-currency a half-filled form.
              currencyCode: ref.read(currencyControllerProvider).value ??
                  AppCurrencies.defaultCurrency.code,
            )
          : TransactionFormViewState.fromTile(original);

  void setAmountText(String text) => state = state.copyWith(amountText: text);

  void setReminderMinutes(int? minutes) =>
      state = state.copyWith(reminderMinutes: minutes);

  void setNote(String note) => state = state.copyWith(note: note);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setRepeat(String frequency) =>
      state = state.copyWith(repeat: frequency, customRecurrence: null);

  void setCustomRecurrence(CustomRecurrence rule) =>
      state = state.copyWith(repeat: 'CUSTOM', customRecurrence: rule);

  void selectCategory(String id) => state = state.copyWith(categoryId: id);

  void selectToAccount(String id) => state = state.copyWith(toAccountId: id);

  /// The mode owns the frequency: a series mode always has one (MONTHLY floor,
  /// never "does not repeat" — the mode already answered that), and the other
  /// modes never do. Entering 计划 also drops picked files: a series cannot
  /// carry them, and an invisible list is a leak.
  void setMode(TransactionFormMode mode) {
    if (mode == state.mode) return;
    final wantsFrequency = mode == TransactionFormMode.repeating;
    state = state.copyWith(
      mode: mode,
      customRecurrence: wantsFrequency ? state.customRecurrence : null,
      repeat: wantsFrequency
          ? (state.repeat == TransactionFormViewState.repeatNever
              ? 'MONTHLY'
              : state.repeat)
          : TransactionFormViewState.repeatNever,
      pendingAttachments: mode == TransactionFormMode.planned
          ? const []
          : state.pendingAttachments,
    );
  }

  /// Switching kind clears what the new kind cannot carry, rather than leaving
  /// a value in a field it does not render. A transfer cannot be a series
  /// (ADR-0002) and has no plan to make either, so the mode goes with them.
  void setType(TransactionKind type) {
    if (type == state.type) return;
    if (type == TransactionKind.transfer) {
      state = state.copyWith(
        type: type,
        categoryId: null,
        toAccountId: null,
        mode: TransactionFormMode.defaultMode,
        repeat: TransactionFormViewState.repeatNever,
        customRecurrence: null,
      );
      return;
    }
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
    if (state.mode == TransactionFormMode.planned) {
      return false; // no money moves
    }
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

    // 计划: nothing is recorded and nothing moves. The series *is* the save —
    // a one-shot rule whose single instance is the bill being planned — so a
    // failure here is the save failing, and no attachments are imported (the
    // row that would carry them is never created).
    if (form.mode == TransactionFormMode.planned) {
      final series = await _createPlannedSeries(form, amountMinor);
      return switch (series) {
        Failure(:final code) => TransactionFormSaveFailed(code),
        Success() => const TransactionFormSaved(),
      };
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
      TransactionKind.openingBalance ||
      TransactionKind.balanceAdjustment =>
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
    if (!form.canRepeat ||
        !form.wantsSeries ||
        form.repeat == TransactionFormViewState.repeatNever) {
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
    return ref.read(recurringServiceProvider).createSeries(
          type: form.type == TransactionKind.income
              ? RecurringSeriesKind.income
              : RecurringSeriesKind.expense,
          amountMinor: amountMinor,
          accountId: form.accountId!,
          categoryId: form.categoryId!,
          description: _seriesDescription(form),
          frequency: form.customRecurrence?.frequency ?? form.repeat,
          interval: form.customRecurrence?.interval ?? 1,
          startDate: form.customRecurrence?.startDate ??
              nextOccurrence(form.date, form.repeat),
          endDate: form.customRecurrence?.endDate,
          countLimit: form.customRecurrence?.countLimit,
          weekdays: form.customRecurrence?.weekdays ?? const [],
          autoPost: false,
          reminderMinutes: form.reminderMinutes,
          mode: _seriesMode(form.mode),
        );
  }

  /// 计划: the series is the whole save. A one-shot rule (`startDate ==
  /// endDate`, UNTIL is inclusive) materializes exactly the one bill being
  /// planned, on the chosen day, into the pending list.
  Future<Result<void>> _createPlannedSeries(
    TransactionFormViewState form,
    int amountMinor,
  ) {
    return ref.read(recurringServiceProvider).createSeries(
          type: form.type == TransactionKind.income
              ? RecurringSeriesKind.income
              : RecurringSeriesKind.expense,
          amountMinor: amountMinor,
          accountId: form.accountId!,
          categoryId: form.categoryId!,
          description: _seriesDescription(form),
          // Meaningless for a one-shot (UNTIL caps it at one instance), but
          // the column is non-null.
          frequency: 'MONTHLY',
          interval: 1,
          startDate: form.date,
          endDate: form.date,
          reminderMinutes: form.reminderMinutes,
          mode: RecurringSeriesMode.planned,
        );
  }

  /// A series must be named — the ledger list shows this. The note is what the
  /// user called it; failing that, the category.
  String _seriesDescription(TransactionFormViewState form) {
    final categories = ref.read(categoryListProvider(form.categoryType)).value;
    final categoryName =
        categories?.where((c) => c.id == form.categoryId).firstOrNull?.name ??
            '';
    return form.note.trim().isEmpty ? categoryName : form.note.trim();
  }

  /// The persisted creation mode. [TransactionFormMode.defaultMode] never
  /// creates a series, so it has no counterpart here.
  RecurringSeriesMode _seriesMode(TransactionFormMode mode) => switch (mode) {
        TransactionFormMode.planned => RecurringSeriesMode.planned,
        TransactionFormMode.repeating => RecurringSeriesMode.repeating,
        TransactionFormMode.defaultMode =>
          throw StateError('a default entry creates no series'),
      };

  /// The first occurrence *after* the one being recorded — the entry the user
  /// is making now is the current period, so the series picks up from the next
  /// and the two never overlap.
  ///
  /// Calendar arithmetic, so 31 Jan rolls to 28/29 Feb rather than spilling
  /// into March.
  static DateTime nextOccurrence(DateTime from, String frequency) {
    if (frequency == 'DAILY') {
      return DateTime(from.year, from.month, from.day + 1, from.hour,
          from.minute, from.second, from.millisecond, from.microsecond);
    }
    if (frequency == 'WEEKLY') {
      return DateTime(from.year, from.month, from.day + 7, from.hour,
          from.minute, from.second, from.millisecond, from.microsecond);
    }
    final month = frequency == 'YEARLY' ? from.month : from.month + 1;
    final year = frequency == 'YEARLY' ? from.year + 1 : from.year;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
        year,
        month,
        from.day > lastDay ? lastDay : from.day,
        from.hour,
        from.minute,
        from.second,
        from.millisecond,
        from.microsecond);
  }
}
