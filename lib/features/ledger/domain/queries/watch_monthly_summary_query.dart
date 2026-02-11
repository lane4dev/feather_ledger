import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/features/ledger/data/repositories/ledger_repository.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/monthly_summary.dart';

part 'watch_monthly_summary_query.g.dart';

class WatchMonthlySummaryQuery {
  final LedgerRepository _ledgerRepository;

  WatchMonthlySummaryQuery(this._ledgerRepository);

  Stream<MonthlySummary> execute(DateTime month) {
    return _ledgerRepository.watchMonthlySummary(month);
  }
}

@riverpod
WatchMonthlySummaryQuery watchMonthlySummaryQuery(Ref ref) {
  final repo = ref.watch(ledgerRepositoryProvider);
  return WatchMonthlySummaryQuery(repo);
}
