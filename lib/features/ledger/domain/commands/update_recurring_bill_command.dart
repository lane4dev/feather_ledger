import 'package:feather_ledger/features/ledger/domain/commands/project_recurring_events_command.dart';
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/data/repositories/preferences_repository.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/posting_context.dart';

part 'update_recurring_bill_command.g.dart';

/// Edits a recurring bill at one of the three [RecurringScope]s
/// (spec 004, US2).
///
/// Editing is not symmetric with what a bill *is*. A row in
/// `scheduled_transactions_view` holds a date and an amount; its category,
/// account and description live on the series and are resolved when read. So
/// the scope decides how much has somewhere to be written:
///
/// - [RecurringScope.thisOnly] can only carry the amount and the date, because
///   the row has nowhere else to put anything. Category and account are the
///   series', and changing them for one occurrence among many is not
///   representable — the caller passes the series' current values and they are
///   ignored here rather than silently written to every other bill.
/// - [RecurringScope.thisAndFollowing] ends the old rule the day before this
///   bill and starts a new one from the edited values, so the change reaches
///   forward without rewriting history.
/// - [RecurringScope.all] rewrites the series' template. Its pending rows are
///   dropped and re-materialized, because a row's id encodes its date and a
///   shifted schedule makes every old id stale.
///
/// Nothing here records a transaction: a bill already recorded is a real
/// movement with its own event, and editing a *pending* one moves no money.
/// That is also why there is no `commandId` — no event is appended.
class UpdateRecurringBillCommand {
  final RecurringRepository _recurringRepository;
  final PostingContextResolver _context;

  /// Local eligibility boundaries (spec 006, US32). Null means clock-rollback
  /// detection is unavailable — eligibility still applies, but a rollback is
  /// never noticed rather than wrongly latched.
  final PreferencesRepository? preferences;

  UpdateRecurringBillCommand(this._recurringRepository, this._context,
      {this.preferences});

  /// [categoryId], [accountId] and [description] are read only by the two
  /// series scopes; `thisOnly` ignores them.
  ///
  /// Returns the ids of any re-materialized bills the edit must latch as
  /// permanently manual (spec 006, US32). An empty list means nothing to
  /// latch.
  Future<List<String>> execute(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) async {
    if (amountMinor <= 0) {
      throw const CommandRejected(
          LedgerErrorCode.invalidAmount, 'Bill amount must be positive');
    }

    final scheduled = await _requireScheduled(scheduledId);
    final series = await _requireSeries(scheduled.seriesId);

    // An edit is a real change only when one of the fields it can carry
    // actually differs — a no-op save must not flip eligibility (US32).
    final now = DateTime.now();
    final actuallyChanged = amountMinor != scheduled.amountMinor ||
        !_sameDay(date, scheduled.date) ||
        categoryId != series.categoryId ||
        accountId != series.accountId ||
        description != series.description;

    // A bill that was already due, or whose new date is in the past, turns
    // manual on a real edit (US32): auto-posting a bill the user just touched
    // would be a surprise.
    final wasDue = !scheduled.date.isAfter(now);
    final movedToPast = !date.isAfter(now);

    // Clock rollback: if the wall clock is *before* the last decision we saw,
    // due/not-due ordering is unreliable, so the touched bill goes manual.
    // Not promised to catch every offline rollback (spec 006, US32).
    var rollback = false;
    final prefs = preferences;
    if (prefs != null) {
      final lastSeen = prefs.getLastSeenWallClock();
      rollback = lastSeen != null && now.isBefore(lastSeen);
      await prefs.setLastSeenWallClock(now);
    }

    final shouldLatch = actuallyChanged && (wasDue || movedToPast || rollback);

    switch (scope) {
      case RecurringScope.thisOnly:
        await _updateOne(scheduled,
            amountMinor: amountMinor, date: date, shouldLatch: shouldLatch);
        return const [];
      case RecurringScope.thisAndFollowing:
        await _context.resolveForKind(
          accountId: accountId,
          categoryId: categoryId,
          kind: series.type.toTransactionKind,
        );
        final newSeriesId = await _splitFrom(
          scheduled,
          series,
          amountMinor: amountMinor,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          description: description,
        );
        return shouldLatch
            ? [
                scheduledInstanceId(
                    newSeriesId, _atTimeOf(date, scheduled.date))
              ]
            : const [];
      case RecurringScope.all:
        await _context.resolveForKind(
          accountId: accountId,
          categoryId: categoryId,
          kind: series.type.toTransactionKind,
        );
        await _updateWholeSeries(
          series: series,
          scheduled: scheduled,
          amountMinor: amountMinor,
          date: date,
          categoryId: categoryId,
          accountId: accountId,
          description: description,
        );
        return shouldLatch
            ? [
                scheduledInstanceId(series.id, _atTimeOf(date, scheduled.date))
              ]
            : const [];
    }
  }

  /// One bill, and only its amount and date. The series is not touched, so
  /// every other bill keeps what the rule says.
  Future<void> _updateOne(
    ScheduledTransactionViewRow scheduled, {
    required int amountMinor,
    required DateTime date,
    required bool shouldLatch,
  }) async {
    if (_sameDay(scheduled.date, date)) {
      // Same day: the row keeps its identity, so the amount moves in place.
      await _recurringRepository.insertOrUpdateScheduled(_row(
        scheduled,
        amountMinor: amountMinor,
        autoPostEligible: shouldLatch ? false : null,
      ));
      return;
    }

    // The picker hands back a day; the bill carries the series' clock time.
    // Keeping that time is not cosmetic — it is what makes the moved row's id
    // the same one the rule would derive for that day, so the collision check
    // below compares like with like.
    final moved = _atTimeOf(date, scheduled.date);

    // A new day means a new row. Ids encode the date and materialization
    // recomputes them, so reusing the old id would leave a row that the rule
    // counts at its old date *and* re-creates at the new one.
    final movedId = scheduledInstanceId(scheduled.seriesId, moved);
    if (await _recurringRepository.getScheduled(movedId) != null) {
      throw const CommandRejected(LedgerErrorCode.scheduledDateTaken,
          'This series already has a bill on that date');
    }

    // The rule still produces the original date. The tombstone is what stops
    // the next materialization from putting the bill straight back.
    await _recurringRepository.insertOrUpdateScheduled(_row(
      scheduled,
      status: ScheduledTransactionStatus.skipped,
    ));
    await _recurringRepository.insertOrUpdateScheduled(
      ScheduledTransactionsViewCompanion(
        id: Value(movedId),
        seriesId: Value(scheduled.seriesId),
        date: Value(moved),
        amountMinor: Value(amountMinor),
        status: Value(ScheduledTransactionStatus.scheduled.toStorage()),
        transactionId: const Value(null),
        autoPostEligible: Value(!shouldLatch),
      ),
    );
  }

  /// Ends the old rule the day before [scheduled] and starts a new one from
  /// the edited values. Returns the new series' id, so the caller can latch
  /// its re-materialized bill if the edit must turn manual (US32).
  Future<String> _splitFrom(
    ScheduledTransactionViewRow scheduled,
    RecurringSeriesRow series, {
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) async {
    final cut = scheduled.date;
    final newSeriesId = const Uuid().v4();
    // Same clock time as the rule being replaced, so the new bills land on
    // the same part of the day as the old ones did.
    final restart = _atTimeOf(date, cut);

    final priorOccurrences = series.countLimit == null ||
            !cut.toUtc().isAfter(series.startDate.toUtc())
        ? 0
        : ProjectRecurringEventsCommand.ruleForSeries(series)
            .getInstances(start: series.startDate.toUtc(), before: cut.toUtc())
            .length;
    final remainingCount = series.countLimit == null
        ? null
        : (series.countLimit! - priorOccurrences).clamp(1, series.countLimit!);

    await _recurringRepository.saveSeries(
      _series(series, endDate: Value(_dayBefore(cut))),
    );
    await _recurringRepository.deletePending(series.id, from: cut);

    await _recurringRepository.saveSeries(RecurringSeriesCompanion.insert(
      id: newSeriesId,
      // Retain BYDAY and the original rule metadata across a split.
      rrule: _shiftWeekdays(series.rrule, _daysBetween(cut, restart)),
      startDate: restart,
      // Inherited as-is. If the edit moves the bill past the old end date the
      // new rule simply produces nothing, which is what the dates say.
      endDate: Value(series.endDate),
      frequency: series.frequency,
      interval: Value(series.interval),
      countLimit: Value(remainingCount),
      amountMinor: amountMinor,
      description: description,
      categoryId: categoryId,
      accountId: accountId,
      type: series.type,
      // The split is an edit of the same subscription, not a new series.
      autoPost: Value(series.autoPost),
      reminderMinutes: Value(series.reminderMinutes),
    ));

    // A bill the old rule already recorded must not be billed again by the
    // new one. A skipped row is the tombstone materialization respects, and
    // the recorded transaction itself is left alone.
    for (final row
        in await _recurringRepository.scheduledForSeries(series.id)) {
      if (decodeScheduledStatus(row.status) !=
          ScheduledTransactionStatus.posted) {
        continue;
      }
      if (row.date.isBefore(cut)) continue;
      await _recurringRepository.insertOrUpdateScheduled(
        ScheduledTransactionsViewCompanion(
          id: Value(scheduledInstanceId(newSeriesId, row.date)),
          seriesId: Value(newSeriesId),
          date: Value(row.date),
          amountMinor: Value(amountMinor),
          status: Value(ScheduledTransactionStatus.skipped.toStorage()),
          transactionId: const Value(null),
        ),
      );
    }

    return newSeriesId;
  }

  /// Rewrites the series' template and rebuilds its pending bills.
  ///
  /// The rows are dropped rather than updated because ids encode dates: a
  /// shifted schedule makes every pending id stale, and stale ids read as
  /// "missing" to materialization, which would then bill every date twice.
  Future<void> _updateWholeSeries({
    required RecurringSeriesRow series,
    required ScheduledTransactionViewRow scheduled,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) async {
    // Moving this bill's date moves the whole schedule by the same number of
    // days, so the rent that came on the 22nd comes on the 25th from now on.
    final shift = _daysBetween(scheduled.date, date);

    await _recurringRepository.saveSeries(
      _series(
        series,
        startDate: _addDays(series.startDate, shift),
        rrule: _shiftWeekdays(series.rrule, shift),
        amountMinor: amountMinor,
        categoryId: categoryId,
        accountId: accountId,
        description: description,
      ),
    );
    await _recurringRepository.deletePending(series.id);
  }

  Future<ScheduledTransactionViewRow> _requireScheduled(String id) async {
    final scheduled = await _recurringRepository.getScheduled(id);
    if (scheduled == null) {
      throw CommandRejected(LedgerErrorCode.transactionNotFound,
          'Scheduled instance $id not found');
    }
    if (decodeScheduledStatus(scheduled.status) ==
        ScheduledTransactionStatus.posted) {
      throw const CommandRejected(LedgerErrorCode.scheduledAlreadyPosted,
          'Scheduled instance already posted');
    }
    return scheduled;
  }

  Future<RecurringSeriesRow> _requireSeries(String id) async {
    final series = await _recurringRepository.getSeries(id);
    if (series == null) {
      throw CommandRejected(
          LedgerErrorCode.transactionNotFound, 'Series $id not found');
    }
    return series;
  }

  /// A copy of [row] with the given fields replaced — the shape every write
  /// to the CRUD-exempt table takes.
  static ScheduledTransactionsViewCompanion _row(
    ScheduledTransactionViewRow row, {
    int? amountMinor,
    ScheduledTransactionStatus? status,
    bool? autoPostEligible,
  }) =>
      ScheduledTransactionsViewCompanion(
        id: Value(row.id),
        seriesId: Value(row.seriesId),
        date: Value(row.date),
        amountMinor: Value(amountMinor ?? row.amountMinor),
        status:
            Value((status ?? decodeScheduledStatus(row.status)).toStorage()),
        transactionId: Value(row.transactionId),
        autoPostEligible: Value(autoPostEligible ?? row.autoPostEligible),
      );

  /// A copy of [series] with the given fields replaced.
  static RecurringSeriesCompanion _series(
    RecurringSeriesRow series, {
    DateTime? startDate,
    String? rrule,
    Value<DateTime?>? endDate,
    int? amountMinor,
    String? categoryId,
    String? accountId,
    String? description,
  }) =>
      RecurringSeriesCompanion(
        id: Value(series.id),
        rrule: Value(rrule ?? series.rrule),
        startDate: Value(startDate ?? series.startDate),
        endDate: endDate ?? Value(series.endDate),
        frequency: Value(series.frequency),
        interval: Value(series.interval),
        countLimit: Value(series.countLimit),
        amountMinor: Value(amountMinor ?? series.amountMinor),
        description: Value(description ?? series.description),
        categoryId: Value(categoryId ?? series.categoryId),
        accountId: Value(accountId ?? series.accountId),
        type: Value(series.type),
        autoPost: Value(series.autoPost),
        reminderMinutes: Value(series.reminderMinutes),
      );

  static String _shiftWeekdays(String rule, int shift) {
    if (shift == 0) return rule;
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return rule.replaceAllMapped(RegExp(r'(^|;)BYDAY=([^;]+)'), (match) {
      final shifted = match.group(2)!.split(',').map((day) {
        final index = days.indexOf(day);
        return index < 0 ? day : days[(index + shift) % 7];
      }).join(',');
      return '${match.group(1)}BYDAY=$shifted';
    });
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// [day]'s calendar date carrying [template]'s clock time. Bills are chosen
  /// by day but stored at the series' time, and every helper here keeps that
  /// pairing so ids stay derivable.
  static DateTime _atTimeOf(DateTime day, DateTime template) => DateTime(
        day.year,
        day.month,
        day.day,
        template.hour,
        template.minute,
        template.second,
        template.millisecond,
      );

  static DateTime _dayBefore(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day - 1,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
      );

  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime(to.year, to.month, to.day)
          .difference(DateTime(from.year, from.month, from.day))
          .inDays;

  static DateTime _addDays(DateTime date, int days) => DateTime(
        date.year,
        date.month,
        date.day + days,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
      );
}

@riverpod
UpdateRecurringBillCommand updateRecurringBillCommand(Ref ref) {
  return UpdateRecurringBillCommand(
    ref.watch(recurringRepositoryProvider),
    ref.watch(postingContextResolverProvider),
    preferences: ref.watch(preferencesRepositoryProvider).value,
  );
}
