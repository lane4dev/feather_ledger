import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/core/data/database/daos/budget_dao.dart';
import 'package:feather_ledger/core/domain/clock/clock.dart';
import 'package:feather_ledger/core/domain/recurrence/recurrence_expander.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../entities/budget_entities.dart';
import '../services/budget_calculator.dart';
import '../services/budget_service.dart';
import '../value_objects/budget_value_objects.dart';

part 'watch_month_budget_query.g.dart';

/// Inclusive forward horizon, in calendar months, of the read-side virtual
/// pending overlay (ADR-0008 invariant 6): the Track month plus the following
/// [kBudgetVirtualPendingHorizonMonths] Plan months.
const kBudgetVirtualPendingHorizonMonths =
    RecurrenceExpander.virtualPendingHorizonMonths;

/// Whether the virtual pending overlay applies to [targetYm] at [now].
///
/// Past the horizon the overlay is skipped silently — physical pending rows
/// already materialized for that month are still counted.
bool budgetIncludesVirtualPending(YearMonth targetYm, DateTime now) =>
    RecurrenceExpander.isWithinVirtualPendingHorizon(
      year: targetYm.year,
      month: targetYm.month,
      now: now,
    );

class WatchMonthBudgetQuery {
  final BudgetRepository _repository;
  final DomainClock _clock;

  WatchMonthBudgetQuery(
    this._repository, {
    DomainClock? clock,
  }) : _clock = clock ?? const SystemClock();

  Stream<MonthBudgetSummary> execute({
    required String currencyCode,
    required YearMonth month,
  }) {
    final now = _clock.now();
    final includeVirtual = budgetIncludesVirtualPending(month, now);
    final summaryStream =
        _repository.watchMonthBudgetSummary(currencyCode, month);
    final pendingStream = _repository.watchMonthPendingExpenses(
      currencyCode,
      month,
      includeVirtual: includeVirtual,
    );

    return _combineLatest2(
      summaryStream,
      pendingStream,
      (BudgetMonthRawSummary raw, BudgetMonthPendingRaw pending) =>
          BudgetCalculator.compute(
        currencyCode: currencyCode,
        raw: raw,
        pending: pending,
        targetYm: month,
        now: now,
      ),
    );
  }
}

Stream<R> _combineLatest2<A, B, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  R Function(A a, B b) combiner,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? lastA;
  B? lastB;
  var hasA = false;
  var hasB = false;

  void emitIfReady() {
    if (hasA && hasB && !controller.isClosed) {
      controller.add(combiner(lastA as A, lastB as B));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subA = streamA.listen(
        (a) {
          lastA = a;
          hasA = true;
          emitIfReady();
        },
        onError: controller.addError,
      );
      subB = streamB.listen(
        (b) {
          lastB = b;
          hasB = true;
          emitIfReady();
        },
        onError: controller.addError,
      );
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}

@riverpod
WatchMonthBudgetQuery watchMonthBudgetQuery(Ref ref) {
  return WatchMonthBudgetQuery(
    ref.watch(budgetRepositoryProvider),
    clock: ref.watch(budgetClockProvider),
  );
}
