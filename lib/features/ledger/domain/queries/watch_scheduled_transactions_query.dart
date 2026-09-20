import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/data/repositories/recurring_repository.dart';

part 'watch_scheduled_transactions_query.g.dart';

class WatchScheduledTransactionsQuery {
  final RecurringRepository _recurringRepository;

  WatchScheduledTransactionsQuery(this._recurringRepository);

  /// [currencyCode] scopes the pending-bill list to one ledger currency
  /// (spec 006); null returns every currency — used by the catch-up path,
  /// which posts due instances regardless of the screen's currency.
  Stream<List<ScheduledTransactionEntity>> execute({String? currencyCode}) {
    return _recurringRepository
        .watchAllScheduled()
        .map((items) => items
            .where((s) =>
                currencyCode == null ||
                s.account?.currencyCode == currencyCode)
            .toList());
  }

  /// Latches a bill as permanently manual (spec 006, US31): it stays
  /// `scheduled` and renders as a normal pending row, but [catchUpAutoPosted]
  /// never posts it — not even after its switch or currency returns.
  Future<void> markAutoPostIneligible(String id) =>
      _recurringRepository.markAutoPostIneligible(id);

  /// Latches every still-eligible pending bill of [seriesId] due at or before
  /// [cutoff] (spec 006, US32): a series created already past its first due
  /// date must never auto-post those bills.
  Future<void> markSeriesIneligibleBefore(String seriesId, DateTime cutoff) =>
      _recurringRepository.markSeriesIneligibleBefore(seriesId, cutoff);
}

@riverpod
WatchScheduledTransactionsQuery watchScheduledTransactionsQuery(Ref ref) {
  return WatchScheduledTransactionsQuery(
      ref.watch(recurringRepositoryProvider));
}
