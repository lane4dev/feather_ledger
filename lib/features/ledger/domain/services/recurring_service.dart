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
import 'package:feather_ledger/features/ledger/domain/commands/update_recurring_bill_command.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_scheduled_transaction_query.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_scheduled_transactions_query.dart';

part 'recurring_service.g.dart';

class RecurringService {
  final CreateRecurringSeriesCommand _createSeries;
  final DeleteRecurringBillCommand _deleteBill;
  final UpdateRecurringBillCommand _updateBill;
  final ConvertScheduledToPostedCommand _postInstance;
  final ProjectRecurringEventsCommand _materialize;
  final WatchScheduledTransactionsQuery _watchScheduled;
  final GetScheduledTransactionQuery _getScheduled;
  final RecurringRepository _recurringRepository;
  final prefs_api.PreferencesRepository? _preferences;
  final DomainClock _clock;

  RecurringService(
    this._createSeries,
    this._deleteBill,
    this._updateBill,
    this._postInstance,
    this._materialize,
    this._watchScheduled,
    this._getScheduled,
    this._recurringRepository, {
    prefs_api.PreferencesRepository? preferences,
    DomainClock? clock,
  })  : _preferences = preferences,
        _clock = clock ?? const SystemClock();

  Future<Result<String>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    String description = '',
    required String frequency,
    int interval = 1,
    required DateTime startDate,
    DateTime? endDate,
    int? countLimit,
    List<int> weekdays = const [],
    bool autoPost = false,
    int? reminderMinutes,
    RecurringSeriesMode? mode,
  }) =>
      guard(() async {
        final seriesId = const Uuid().v4();
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
          endDate: endDate,
          countLimit: countLimit,
          weekdays: weekdays,
          autoPost: autoPost,
          reminderMinutes: reminderMinutes,
          mode: mode ?? RecurringSeriesMode.repeating,
        );
        await _materialize.execute();
        if (autoPost) {
          final now = _clock.now();
          await _recurringRepository.markSeriesManualOnlyBefore(seriesId, now);
        }
        return seriesId;
      });

  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) =>
      guard(() => _deleteBill.execute(scheduledId: scheduledId, scope: scope));

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
        final seriesIdToLatch = await _updateBill.execute(
          scheduledId: scheduledId,
          scope: scope,
          amountMinor: amountMinor,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          description: description,
          frequency: frequency,
          interval: interval,
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
        if (seriesIdToLatch != null) {
          await _recurringRepository.markSeriesManualOnlyBefore(
              seriesIdToLatch, _clock.now());
        }
      });

  Future<Result<void>> postInstance(String scheduledId,
      {String? commandId}) async {
    final result = await guard(() => _postInstance.execute(
          scheduledId,
          commandId: commandId ?? const Uuid().v4(),
        ));
    if (result is Success<void>) {
      try {
        await materialize();
      } catch (_) {
        // Materialization is also retried on launch.
      }
    }
    return result;
  }

  Future<int> materialize() => _materialize.execute();

  Future<int> catchUpAutoPosted({String? accountId}) async {
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
      if (currentCurrency != null &&
          instance.account?.currencyCode != currentCurrency) {
        return false;
      }
      return !instance.effectiveDate.isAfter(now);
    }).toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));

    return _postAutoDueInstances(due);
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
    for (final instance in backlog) {
      await _recurringRepository.markManualOnly(instance.id);
    }
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
      final result = await postInstance(
        instance.id,
        commandId: 'autopost-${instance.id}',
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
    preferences: ref.watch(preferencesRepositoryProvider).value,
  );
}
