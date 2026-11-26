import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/data/transaction_attachment_store.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/recurrence/distant_past_guard.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';

import '../models/transaction_tile_ui_model.dart';
import '../models/custom_recurrence.dart';
import 'transaction_form_view_state.dart';

part 'transaction_form_view_model.g.dart';

/// How a save ended.
///
/// The view model never touches a snackbar, a dialog or a route: it says what
/// happened and the screen decides how to say it. Two cases, because the
/// overdraft question — "this will overdraw the account, continue?" — is asked
/// *before* the write, not after it, and lives as [wouldOverdraft].
sealed class TransactionFormOutcome {
  const TransactionFormOutcome();
}

/// Recorded (or, for planned/repeating modes, the series was created).
final class TransactionFormSaved extends TransactionFormOutcome {
  final int autoPostedCount;

  const TransactionFormSaved({this.autoPostedCount = 0});
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
  bool _plannedAutoPostTouched = false;
  bool _repeatingAutoPostTouched = false;
  bool _plannedAutoPost = false;
  bool _repeatingAutoPost = false;
  bool _accountTouched = false;

  @override
  TransactionFormViewState build(TransactionTileUiModel? original) {
    _plannedAutoPostTouched = false;
    _repeatingAutoPostTouched = false;
    _plannedAutoPost = false;
    _repeatingAutoPost = false;
    _accountTouched = false;
    if (original != null) {
      return TransactionFormViewState.fromTile(original);
    }
    final prefsAsync = ref.read(preferencesRepositoryProvider);
    _plannedAutoPost = prefsAsync.value?.getLastPlannedAutoPost() ?? false;
    _repeatingAutoPost = prefsAsync.value?.getLastRepeatingAutoPost() ?? false;
    final currencyCode = ref.read(currencyControllerProvider).value ??
        AppCurrencies.defaultCurrency.code;
    final rememberedId = prefsAsync.value?.getLastTransactionAccount();
    final accounts = ref.read(accountUiListProvider).value;
    final initialAccount = accounts
        ?.where((item) =>
            item.account.id == rememberedId &&
            !item.account.archived &&
            item.account.currencyCode == currencyCode)
        .firstOrNull;
    ref.listen(accountUiListProvider, (_, __) => _restoreAccount());
    if (prefsAsync.isLoading) {
      ref.listen(preferencesRepositoryProvider, (_, next) {
        final repo = next.value;
        if (repo != null) {
          if (!_plannedAutoPostTouched) {
            _plannedAutoPost = repo.getLastPlannedAutoPost();
            if (state.mode == TransactionFormMode.planned) {
              state = state.copyWith(autoPost: _plannedAutoPost);
            }
          }
          if (!_repeatingAutoPostTouched) {
            _repeatingAutoPost = repo.getLastRepeatingAutoPost();
            if (state.mode == TransactionFormMode.repeating) {
              state = state.copyWith(autoPost: _repeatingAutoPost);
            }
          }
          _restoreAccount();
        }
      });
    }
    return TransactionFormViewState.initial(
      // The form locks its currency at open time (spec 006, US21): a
      // one-time read, not a watch, so a later setting change cannot
      // re-currency a half-filled form.
      currencyCode: currencyCode,
    ).copyWith(accountId: initialAccount?.account.id);
  }

  void _restoreAccount() {
    if (_accountTouched || state.accountId != null) return;
    final id = ref
        .read(preferencesRepositoryProvider)
        .value
        ?.getLastTransactionAccount();
    if (id == null) return;
    final accounts = ref.read(accountUiListProvider).value;
    final account = state
        .activeAccounts(accounts ?? const [])
        .where((item) => item.account.id == id)
        .firstOrNull;
    if (account != null) state = state.copyWith(accountId: id);
  }

  void setAutoPost(bool enabled) {
    final isPlanned = state.mode == TransactionFormMode.planned;
    if (isPlanned) {
      _plannedAutoPostTouched = true;
      _plannedAutoPost = enabled;
    } else if (state.mode == TransactionFormMode.repeating) {
      _repeatingAutoPostTouched = true;
      _repeatingAutoPost = enabled;
    }
    state = state.copyWith(autoPost: enabled);
    final repo = ref.read(preferencesRepositoryProvider).value;
    if (repo != null) {
      unawaited(isPlanned
          ? repo.setLastPlannedAutoPost(enabled)
          : repo.setLastRepeatingAutoPost(enabled));
    } else {
      unawaited(
        ref.read(preferencesRepositoryProvider.future).then(
              (r) => isPlanned
                  ? r.setLastPlannedAutoPost(enabled)
                  : r.setLastRepeatingAutoPost(enabled),
              onError: (_, __) {},
            ),
      );
    }
  }

  void setAmountText(String text) => state = state.copyWith(amountText: text);

  void setReminderMinutes(int? minutes) =>
      state = state.copyWith(reminderMinutes: minutes);

  void setNote(String note) => state = state.copyWith(note: note);

  void setDate(DateTime date) => state = state.copyWith(
        date: date,
        customRecurrence: state.customRecurrence == null
            ? null
            : CustomRecurrence(
                frequency: state.customRecurrence!.frequency,
                interval: state.customRecurrence!.interval,
                startDate: date,
                weekdays: state.customRecurrence!.weekdays,
                endDate: state.customRecurrence!.endDate,
                countLimit: state.customRecurrence!.countLimit,
              ),
      );

  void setRepeat(String frequency) =>
      state = state.copyWith(repeat: frequency, customRecurrence: null);

  void setCustomRecurrence(CustomRecurrence rule) => state = state.copyWith(
      repeat: 'CUSTOM', customRecurrence: rule, date: rule.startDate);

  void selectCategory(String id) => state = state.copyWith(categoryId: id);

  void selectToAccount(String id) => state = state.copyWith(toAccountId: id);

  /// The mode owns the frequency: a series mode always has one (MONTHLY floor,
  /// never "does not repeat" — the mode already answered that), and the other
  /// modes never do. Entering a series mode (计划 / 重复) also drops picked
  /// files: a series cannot carry them, and an invisible list is a leak.
  void setMode(TransactionFormMode mode) {
    if (mode == state.mode) return;
    final wantsFrequency = mode == TransactionFormMode.repeating;
    final modeAutoPost = switch (mode) {
      TransactionFormMode.planned => _plannedAutoPost,
      TransactionFormMode.repeating => _repeatingAutoPost,
      TransactionFormMode.defaultMode => false,
    };
    state = state.copyWith(
      mode: mode,
      autoPost: modeAutoPost,
      customRecurrence: wantsFrequency ? state.customRecurrence : null,
      repeat: wantsFrequency
          ? (state.repeat == TransactionFormViewState.repeatNever
              ? 'MONTHLY'
              : state.repeat)
          : TransactionFormViewState.repeatNever,
      pendingAttachments: mode == TransactionFormMode.defaultMode
          ? state.pendingAttachments
          : const [],
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
  void selectAccount(String id) {
    _accountTouched = true;
    state = state.copyWith(accountId: id, toAccountId: null);
    unawaited(ref.read(preferencesRepositoryProvider.future).then(
          (repo) => repo.setLastTransactionAccount(id),
          onError: (_, __) {},
        ));
  }

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
    if (state.mode != TransactionFormMode.defaultMode) {
      return false; // series modes create a schedule, not an ad-hoc movement
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

  /// Effective start date when creating a repeating series.
  DateTime get targetRepeatStartDate =>
      state.customRecurrence?.startDate ?? state.date;

  /// Whether creating a repeating series requires the distant-past start-date
  /// confirmation dialog (strictly earlier than 2 calendar months before [now]).
  bool needsDistantPastConfirmation(DateTime now) {
    if (state.mode != TransactionFormMode.repeating) return false;
    return DistantPastStartGuard.isDistantPast(
      targetRepeatStartDate,
      now: now,
    );
  }

  /// Records or corrects the entry, or creates a planned/repeating recurring
  /// series. The screen validates the form first; this re-checks the amount so
  /// that a caller which skipped validation cannot reach a command with junk.
  Future<TransactionFormOutcome> submit({DateTime? materializeFrom}) async {
    final form = state;
    final amountMinor = form.amountMinor;
    if (amountMinor == null) {
      return const TransactionFormSaveFailed(LedgerErrorCode.invalidAmount);
    }

    // 计划 / 重复: nothing is recorded as an ad-hoc transaction. The series
    // *is* the save, starting on the chosen date — the first occurrence stays
    // pending unless `autoPost` is enabled and the occurrence is already due
    // (in which case `createSeries` posts it via ConvertScheduledToPostedCommand
    // with `sourceScheduledBillId` intact).
    if (form.mode != TransactionFormMode.defaultMode) {
      final series = form.mode == TransactionFormMode.planned
          ? await _createPlannedSeries(form, amountMinor)
          : await _startSeries(
              form,
              amountMinor,
              materializeFrom: materializeFrom,
            );
      final count = series is Success
          ? ref.read(recurringServiceProvider).takeLastAutoPostedCount()
          : 0;
      return switch (series) {
        Failure(:final code) => TransactionFormSaveFailed(code),
        Success() => TransactionFormSaved(autoPostedCount: count),
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

    return const TransactionFormSaved();
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

  /// 重复: creates the recurring series starting on the chosen date (or custom
  /// recurrence start date). Does not record an immediate ad-hoc transaction.
  Future<Result<void>> _startSeries(
    TransactionFormViewState form,
    int amountMinor, {
    DateTime? materializeFrom,
  }) {
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
          startDate: form.customRecurrence?.startDate ?? form.date,
          materializeFrom: materializeFrom,
          endDate: form.customRecurrence?.endDate,
          countLimit: form.customRecurrence?.countLimit,
          weekdays: form.customRecurrence?.weekdays ?? const [],
          autoPost: form.autoPost,
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
          autoPost: form.autoPost,
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
}
