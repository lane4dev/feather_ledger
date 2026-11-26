import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/repositories/preferences_repository.dart'
    as prefs_api;
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/create_recurring_series_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/delete_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/restore_skipped_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/commands/update_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_scheduled_transaction_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';

export 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart'
    show MaterializationSummary;

part 'recurring_service.g.dart';

/// Structured outcome of an auto-post catch-up pass.
class AutoPostCatchUpResult {
  /// Number of eligible due bills posted in this pass.
  final int postedCount;

  /// Number of due bills strictly older than [RecurringService.autoPostMaxAge]
  /// (30 days) downgraded to `manualOnly = true` instead of silently posting.
  final int staleLatchedCount;

  /// Number of recent due bills (within 30 days) downgraded to
  /// `manualOnly = true` because the batch exceeded
  /// [RecurringService.autoPostBulkBreakerLimit] (10 bills).
  final int bulkLatchedCount;

  const AutoPostCatchUpResult({
    this.postedCount = 0,
    this.staleLatchedCount = 0,
    this.bulkLatchedCount = 0,
  });

  static const AutoPostCatchUpResult empty = AutoPostCatchUpResult();

  /// Total due auto-post bills diverted to manual review by either circuit
  /// breaker stage.
  int get circuitBreakerLatchedCount => staleLatchedCount + bulkLatchedCount;

  /// Whether either circuit breaker stage tripped in this pass.
  bool get circuitBreakerTripped => circuitBreakerLatchedCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoPostCatchUpResult &&
          other.postedCount == postedCount &&
          other.staleLatchedCount == staleLatchedCount &&
          other.bulkLatchedCount == bulkLatchedCount;

  @override
  int get hashCode =>
      Object.hash(postedCount, staleLatchedCount, bulkLatchedCount);

  @override
  String toString() =>
      'AutoPostCatchUpResult(postedCount: $postedCount, '
      'staleLatchedCount: $staleLatchedCount, '
      'bulkLatchedCount: $bulkLatchedCount)';
}

class RecurringService {
  /// Due auto-post bills strictly older than this duration are never silently
  /// posted; they are latched `manualOnly = true` for manual review.
  static const Duration autoPostMaxAge = Duration(days: 30);

  /// Maximum number of recent due auto-post bills (within [autoPostMaxAge])
  /// allowed to silently auto-post in one catch-up pass before the bulk
  /// circuit breaker trips and latches them `manualOnly = true`.
  static const int autoPostBulkBreakerLimit = 10;

  final CreateRecurringSeriesCommand _createSeries;
  final DeleteRecurringBillCommand _deleteBill;
  final UpdateRecurringBillCommand _updateBill;
  final ConvertScheduledToPostedCommand _postInstance;
  final ProjectRecurringEventsCommand _materialize;
  final WatchScheduledTransactionsQuery _watchScheduled;
  final GetScheduledTransactionQuery _getScheduled;
  final RecurringRepository _recurringRepository;
  final RestoreSkippedBillCommand _restoreSkipped;
  final prefs_api.PreferencesRepository? _preferences;
  final DomainClock _clock;
  int _lastSaveAutoPostedCount = 0;

  RecurringService(
    this._createSeries,
    this._deleteBill,
    this._updateBill,
    this._postInstance,
    this._materialize,
    this._watchScheduled,
    this._getScheduled,
    this._recurringRepository, {
    RestoreSkippedBillCommand? restoreSkipped,
    prefs_api.PreferencesRepository? preferences,
    DomainClock? clock,
  })  : _restoreSkipped =
            restoreSkipped ?? RestoreSkippedBillCommand(_recurringRepository),
        _preferences = preferences,
        _clock = clock ?? const SystemClock();

  int takeLastAutoPostedCount() {
    final count = _lastSaveAutoPostedCount;
    _lastSaveAutoPostedCount = 0;
    return count;
  }

  Future<Result<String>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    String description = '',
    required String frequency,
    int interval = 1,
    required DateTime startDate,
    DateTime? materializeFrom,
    DateTime? endDate,
    int? countLimit,
    List<int> weekdays = const [],
    bool autoPost = false,
    int? reminderMinutes,
    RecurringSeriesMode? mode,
  }) =>
      guard(() async {
        final seriesId = const Uuid().v4();
        final effectiveMode = mode ?? RecurringSeriesMode.repeating;
        await _createSeries.execute(
          id: seriesId,
          type: type,
          amountMinor: amountMinor,
          accountId: accountId,
          categoryId: categoryId,
          description: description,
          frequency: frequency,
          interval: interval,
          startDate: startDate,
          materializeFrom: materializeFrom,
          endDate: endDate,
          countLimit: countLimit,
          weekdays: weekdays,
          autoPost: autoPost,
          reminderMinutes: reminderMinutes,
          mode: effectiveMode,
        );
        await _materialize.execute();
        if (effectiveMode == RecurringSeriesMode.repeating) {
          await _recurringRepository.markSeriesManualOnlyBefore(
            seriesId,
            _clock.today(),
          );
        }
        if (autoPost) {
          _lastSaveAutoPostedCount =
              await catchUpAutoPosted(seriesId: seriesId);
        } else {
          _lastSaveAutoPostedCount = 0;
        }
        return seriesId;
      });

  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) =>
      guard(() => _deleteBill.execute(scheduledId: scheduledId, scope: scope));

  Future<Result<void>> restoreSkippedBill(String scheduledId) =>
      guard(() => _restoreSkipped.execute(scheduledId));

  Future<Result<void>> updateBill(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
    String? frequency,
    int? interval,
    DateTime? materializeFrom,
    DateTime? endDate,
    int? countLimit,
    List<int>? weekdays,
    bool? autoPost,
    int? reminderMinutes,
    bool clearEndDate = false,
    bool clearCountLimit = false,
    bool clearReminder = false,
  }) =>
      guard(() async {
        final updateResult = await _updateBill.execute(
          scheduledId: scheduledId,
          scope: scope,
          amountMinor: amountMinor,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          description: description,
          frequency: frequency,
          interval: interval,
          materializeFrom: materializeFrom,
          endDate: endDate,
          countLimit: countLimit,
          weekdays: weekdays,
          autoPost: autoPost,
          reminderMinutes: reminderMinutes,
          clearEndDate: clearEndDate,
          clearCountLimit: clearCountLimit,
          clearReminder: clearReminder,
        );
        await _materialize.execute();
        if (updateResult.guardPastSeriesId != null) {
          await _recurringRepository.markSeriesManualOnlyBefore(
            updateResult.guardPastSeriesId!,
            _clock.today(),
          );
        }
        if (updateResult.autoPostSeriesId != null) {
          _lastSaveAutoPostedCount = await catchUpAutoPosted(
              seriesId: updateResult.autoPostSeriesId);
        } else {
          _lastSaveAutoPostedCount = 0;
        }
      });

  Future<Result<void>> postInstance(String scheduledId, {String? commandId}) =>
      _postInstanceInternal(
        scheduledId,
        commandId: commandId,
        materializeAfter: true,
      );

  Future<Result<void>> _postInstanceInternal(
    String scheduledId, {
    String? commandId,
    required bool materializeAfter,
  }) async {
    final result = await guard(() => _postInstance.execute(
          scheduledId,
          commandId: commandId ?? const Uuid().v4(),
        ));
    if (result is Success<void> && materializeAfter) {
      try {
        await materialize();
      } catch (_) {
        // Materialization is also retried on launch.
      }
    }
    return result;
  }

  Future<MaterializationSummary> materialize() => _materialize.execute();

  Future<int> catchUpAutoPosted({String? accountId, String? seriesId}) async =>
      (await catchUpAutoPostedWithSummary(
        accountId: accountId,
        seriesId: seriesId,
      ))
          .postedCount;

  /// Runs startup/save auto-post catch-up guarded by the two-stage circuit
  /// breaker:
  /// 1. Any due bill strictly older than 30 days (`effectiveDate < now - 30d`)
  ///    is latched `manualOnly = true` and never silently posted.
  /// 2. If more than 10 recent due bills remain within 30 days, the bulk
  ///    circuit breaker trips and latches all of them `manualOnly = true`.
  ///
  /// Eligible bills are posted in one batch followed by a single
  /// [materialize] pass to avoid O(N^2) materialization amplification.
  Future<AutoPostCatchUpResult> catchUpAutoPostedWithSummary({
    String? accountId,
    String? seriesId,
  }) async {
    final now = _clock.now();
    final currentCurrency = _preferences?.getCurrency();
    final scheduled = await _watchScheduled.execute().first;
    final due = scheduled.where((instance) {
      final series = instance.recurringTransactionSeries;
      if (series == null || !series.isActive || !series.autoPost) return false;
      if (instance.manualOnly) return false;
      if (instance.status != ScheduledTransactionStatus.scheduled) return false;
      if (instance.account?.archived == true) return false;
      if (accountId != null && series.accountId != accountId) return false;
      if (seriesId != null && instance.seriesId != seriesId) return false;
      if (currentCurrency != null &&
          instance.account?.currencyCode != currentCurrency) {
        return false;
      }
      return !instance.effectiveDate.isAfter(now);
    }).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    if (due.isEmpty) return AutoPostCatchUpResult.empty;

    final staleCutoff = now.subtract(autoPostMaxAge);
    final stale = <ScheduledTransactionEntity>[];
    final recent = <ScheduledTransactionEntity>[];
    for (final instance in due) {
      if (instance.effectiveDate.isBefore(staleCutoff)) {
        stale.add(instance);
      } else {
        recent.add(instance);
      }
    }

    if (stale.isNotEmpty) {
      await _recurringRepository
          .markManualOnlyBatch(stale.map((i) => i.id).toList());
    }

    if (recent.length > autoPostBulkBreakerLimit) {
      await _recurringRepository
          .markManualOnlyBatch(recent.map((i) => i.id).toList());
      return AutoPostCatchUpResult(
        postedCount: 0,
        staleLatchedCount: stale.length,
        bulkLatchedCount: recent.length,
      );
    }

    final posted = recent.isEmpty ? 0 : await _postAutoDueInstances(recent);
    return AutoPostCatchUpResult(
      postedCount: posted,
      staleLatchedCount: stale.length,
      bulkLatchedCount: 0,
    );
  }

  /// Marks all scheduled instances across every currency with
  /// `effectiveDate <= restoreTime` as `manualOnly = true` after a backup
  /// restore so they never auto-post unexpectedly at launch or currency switch.
  Future<int> markPreRestoreManualOnly([DateTime? restoreTime]) {
    return _recurringRepository
        .markAllScheduledManualOnlyBefore(restoreTime ?? _clock.now());
  }

  /// Returns due auto-posting instances in [currencyCode] that accumulated
  /// while another currency was active (`isActive && autoPost && !manualOnly
  /// && scheduled && effectiveDate <= now`).
  Future<List<ScheduledTransactionEntity>> getCurrencyBacklog(
      String currencyCode) async {
    final now = _clock.now();
    final scheduled = await _watchScheduled.execute().first;
    final backlog = scheduled.where((instance) {
      final series = instance.recurringTransactionSeries;
      if (series == null || !series.isActive || !series.autoPost) return false;
      if (instance.manualOnly) return false;
      if (instance.status != ScheduledTransactionStatus.scheduled) return false;
      if (instance.account?.archived == true) return false;
      if (instance.account?.currencyCode != currencyCode) return false;
      return !instance.effectiveDate.isAfter(now);
    }).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return backlog;
  }

  /// Settles due auto-posting backlog for [currencyCode] after switching back:
  /// either posts all due bills now (`postAll: true`) or freezes them as manual
  /// pending bills (`postAll: false`).
  Future<int> settleCurrencyBacklog(
    String currencyCode, {
    required bool postAll,
  }) async {
    final backlog = await getCurrencyBacklog(currencyCode);
    if (backlog.isEmpty) return 0;
    if (postAll) {
      return _postAutoDueInstances(backlog);
    }
    await _recurringRepository
        .markManualOnlyBatch(backlog.map((i) => i.id).toList());
    return 0;
  }

  Future<int> _postAutoDueInstances(
      List<ScheduledTransactionEntity> due) async {
    var posted = 0;
    for (var i = 0; i < due.length; i++) {
      if (i > 0 && i % 20 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      final instance = due[i];
      final result = await _postInstanceInternal(
        instance.id,
        commandId: 'autopost-${instance.id}',
        materializeAfter: false,
      );
      if (result case Success()) {
        posted++;
      } else if (result case Failure(:final code, :final message)) {
        debugPrint(
            'Auto-post skipped for ${instance.id}: ${code.name} ($message)');
        await _recurringRepository.insertOrUpdateScheduled(
          ScheduledTransactionsViewCompanion(
            id: Value(instance.id),
            seriesId: Value(instance.seriesId),
            occurrenceKey: Value(instance.occurrenceKey),
            scheduledDate: Value(instance.scheduledDate),
            amountOverrideMinor: Value(instance.amountOverrideMinor),
            dateOverride: Value(instance.dateOverride),
            memoOverride: Value(instance.memoOverride),
            status: Value(ScheduledTransactionStatus.failed.toStorage()),
            manualOnly: Value(instance.manualOnly),
            transactionId: Value(instance.transactionId),
          ),
        );
      }
    }
    if (posted > 0) {
      try {
        await materialize();
      } catch (_) {
        // Materialization is also retried on launch.
      }
    }
    return posted;
  }

  Future<List<RecurringSeriesRow>> getAllSeries() =>
      _recurringRepository.getAllRecurringSeries();

  Future<ScheduledTransactionEntity?> getScheduled(String id) =>
      _getScheduled.execute(id);

  Stream<List<ScheduledTransactionEntity>> watchScheduled({
    String? currencyCode,
  }) =>
      _watchScheduled.execute(currencyCode: currencyCode);
}

@riverpod
DomainClock ledgerClock(Ref ref) => const SystemClock();

@riverpod
RecurringService recurringService(Ref ref) {
  return RecurringService(
    ref.watch(createRecurringSeriesCommandProvider),
    ref.watch(deleteRecurringBillCommandProvider),
    ref.watch(updateRecurringBillCommandProvider),
    ref.watch(convertScheduledToPostedCommandProvider),
    ref.watch(projectRecurringEventsCommandProvider),
    ref.watch(watchScheduledTransactionsQueryProvider),
    ref.watch(getScheduledTransactionQueryProvider),
    ref.watch(recurringRepositoryProvider),
    restoreSkipped: ref.watch(restoreSkippedBillCommandProvider),
    preferences: ref.watch(preferencesRepositoryProvider).value,
    clock: ref.watch(ledgerClockProvider),
  );
}
