import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

import '../../domain/entities/ledger_entities.dart';
import '../../domain/services/ledger_service.dart';

import '../mappers/transaction_ui_mapper.dart';
import '../models/ledger_day_group.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import '../models/transaction_tile_ui_model.dart';

import 'ledger_view_state.dart';

part 'ledger_view_model.g.dart';

/// The month's upcoming recurring bills, as rows.
///
/// Only `scheduled` instances: a posted one is already a real transaction and
/// arrives through [ledgerMonthlyTransactions]'s posted half, and a skipped
/// one is a decision the user made and does not want to see again.
///
/// Filtered to the month here rather than in the DAO because the ledger's
/// month view is what needs the slice; the instance table itself stays whole.
@riverpod
Stream<List<TransactionTileUiModel>> monthlyPendingTransactions(
  Ref ref,
  DateTime month,
) {
  final service = ref.watch(ledgerServiceProvider);
  const mapper = TransactionUiMapper();
  // The setting, not the accounts, decides which currency the ledger list
  // shows (spec 006): switching to a currency with no accounts must show an
  // empty ledger, not the other currency's rows.
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;

  return service
      .watchScheduledTransactions(currencyCode: currencyCode)
      .map((instances) {
    final tiles = <TransactionTileUiModel>[];
    for (final instance in instances) {
      if (instance.status != ScheduledTransactionStatus.scheduled) continue;
      if (instance.date.year != month.year ||
          instance.date.month != month.month) {
        continue;
      }
      // A bill whose category or account can no longer be resolved has
      // nothing to render; accounts and categories are archived, not
      // deleted, so this is a corruption guard rather than a normal path.
      final category = instance.category;
      final account = instance.account;
      if (category == null || account == null) continue;

      tiles.add(
        mapper.toPendingTile(instance, category: category, account: account),
      );
    }
    return tiles;
  });
}

/// The set of months (normalized to the first of each month) that hold at
/// least one pending bill in the current currency.
///
/// The month picker marks these so an overdue bill is findable without paging
/// through every month (spec 006, US33). Scoped to the setting's currency,
/// like the rest of the ledger list.
@riverpod
Stream<Set<DateTime>> pendingBillMonths(Ref ref) {
  final service = ref.watch(ledgerServiceProvider);
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;

  return service
      .watchScheduledTransactions(currencyCode: currencyCode)
      .map((instances) {
    final months = <DateTime>{};
    for (final instance in instances) {
      if (instance.status != ScheduledTransactionStatus.scheduled) continue;
      months.add(DateTime(instance.date.year, instance.date.month));
    }
    return months;
  });
}

/// The month's posted transactions and pending bills, newest first.
///
/// Pending bills are merged into the same day grouping so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Both kinds follow the same descending date order, including within a day.
/// Only posted transactions contribute to each day's totals.
///
/// The grouping and each day's totals are built here rather than in the
/// timeline, which is the only place that knows the display currency without
/// being told.
@riverpod
Stream<List<LedgerDayGroup>> ledgerMonthlyTransactions(
  Ref ref,
  DateTime month,
) {
  final service = ref.watch(ledgerServiceProvider);
  const mapper = TransactionUiMapper();
  final symbol = ref.watch(displayCurrencySymbolProvider);
  final currencyCode = ref.watch(currencyControllerProvider).value ??
      AppCurrencies.defaultCurrency.code;

  // Watching this rebuilds the provider when the pending set changes. Each
  // rebuild re-runs the month query, which at personal-ledger scale is
  // cheaper than hand-rolling a stream combine.
  final pending = ref.watch(monthlyPendingTransactionsProvider(month)).value ??
      const <TransactionTileUiModel>[];

  return service
      .watchTransactions(month, currencyCode: currencyCode)
      .map((items) {
    final uiItems = [
      ...items.map(mapper.toTile),
      ...pending,
    ];
    return LedgerDayGroup.group(uiItems, currencySymbol: symbol);
  });
}

/// The currency this ledger is scoped to.
///
/// The setting is the single source of truth for the ledger, search and
/// reports (spec 006). Accounts no longer decide: they are created in
/// whatever the preference was at the time and can therefore hold several
/// currencies at once, with no FX conversion to pick one. The ledger shows
/// the currency the user asked to see — and a setting with no accounts in it
/// is the empty state, not an error.
@riverpod
String ledgerCurrency(Ref ref) =>
    ref.watch(currencyControllerProvider).value ??
    AppCurrencies.defaultCurrency.code;

/// The symbol the ledger writes next to an amount — the setting's currency,
/// for the same reason [ledgerCurrency] exists.
///
/// A provider rather than a constant so the timeline does not have to thread
/// it down: everything that needs it reads it here, at the layer that is
/// already converting the amounts it belongs to.
@riverpod
String displayCurrencySymbol(Ref ref) =>
    AppCurrencies.getSymbol(ref.watch(ledgerCurrencyProvider));

/// The header's three figures for one month, in the ledger's own currency.
///
/// A provider rather than a subscription held by [LedgerViewModel], because
/// **both of its inputs move.** The month moves by definition; the currency is
/// the setting, and a fast switch has to re-scope the snapshot query without
/// a frame where the header labels one currency's figures with another's
/// symbol. `ref.watch` makes the currency a dependency Riverpod can see, so
/// it re-subscribes by itself, and a late emission from the previous
/// subscription is discarded with the old subscription rather than
/// overwriting the new result.
@riverpod
Stream<MonthlySummaryUiModel> ledgerMonthlySummary(Ref ref, DateTime month) {
  final service = ref.watch(ledgerServiceProvider);
  final currencyCode = ref.watch(ledgerCurrencyProvider);

  return service.watchMonthlySnapshot(month, currencyCode: currencyCode).map(
        (totals) => MonthlySummaryUiModel.of(
          balanceMinor: totals.balanceMinor,
          incomeMinor: totals.incomeMinor,
          expenseMinor: totals.expenseMinor,
          // The currency the totals came back in, not the preference: the two
          // can disagree, and the money is the one that is right.
          currencySymbol: AppCurrencies.getSymbol(totals.currencyCode),
        ),
      );
}

/// Session-only count of overdue bills newly materialized at startup.
///
/// Kept purely in memory so dismissing hides the banner for the rest of the
/// session without persisting extra UI flags or re-prompting on already
/// materialized rows.
@Riverpod(keepAlive: true)
class OverdueMaterializationCount extends _$OverdueMaterializationCount {
  @override
  int build() => 0;

  void set(int count) => state = count > 0 ? count : 0;

  void dismiss() => state = 0;
}

@Riverpod(keepAlive: true)
class LedgerViewModel extends _$LedgerViewModel {
  @override
  LedgerViewState build() => LedgerViewState.initial();

  void setMonth(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == state.selectedDate) return;

    state = state.copyWith(
      selectedDate: normalized,
    );
  }

  Future<void> ensureAccountBalanceLoaded(String accountId) async {
    final existing = state.accountBalances[accountId];
    if (existing is AsyncLoading || existing is AsyncData) return;
    await refreshAccountBalance(accountId);
  }

  Future<void> refreshAccountBalance(String accountId) async {
    state = state.copyWith(
      accountBalances: {
        ...state.accountBalances,
        accountId: const AsyncLoading(),
      },
    );

    try {
      final balance = await ref.read(ledgerServiceProvider).accountBalance(
            accountId,
          );
      state = state.copyWith(
        accountBalances: {
          ...state.accountBalances,
          accountId: AsyncData(balance),
        },
      );
    } catch (e, st) {
      state = state.copyWith(
        accountBalances: {
          ...state.accountBalances,
          accountId: AsyncError(e, st),
        },
      );
    }
  }

  /// Reverses a recorded transaction. Its only caller is the ledger list's
  /// delete — the form writes through `TransactionFormViewModel`.
  Future<Result<void>> deleteTransaction(String id) {
    return ref
        .read(ledgerServiceProvider)
        .deleteTransaction(id, commandId: const Uuid().v4());
  }
}
