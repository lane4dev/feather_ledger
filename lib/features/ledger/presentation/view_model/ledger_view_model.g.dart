// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The month's upcoming recurring bills, as rows.
///
/// Only `scheduled` instances: a posted one is already a real transaction and
/// arrives through [ledgerMonthlyTransactions]'s posted half, and a skipped
/// one is a decision the user made and does not want to see again.
///
/// Filtered to the month here rather than in the DAO because the ledger's
/// month view is what needs the slice; the instance table itself stays whole.

@ProviderFor(monthlyPendingTransactions)
final monthlyPendingTransactionsProvider = MonthlyPendingTransactionsFamily._();

/// The month's upcoming recurring bills, as rows.
///
/// Only `scheduled` instances: a posted one is already a real transaction and
/// arrives through [ledgerMonthlyTransactions]'s posted half, and a skipped
/// one is a decision the user made and does not want to see again.
///
/// Filtered to the month here rather than in the DAO because the ledger's
/// month view is what needs the slice; the instance table itself stays whole.

final class MonthlyPendingTransactionsProvider extends $FunctionalProvider<
        AsyncValue<List<TransactionTileUiModel>>,
        List<TransactionTileUiModel>,
        Stream<List<TransactionTileUiModel>>>
    with
        $FutureModifier<List<TransactionTileUiModel>>,
        $StreamProvider<List<TransactionTileUiModel>> {
  /// The month's upcoming recurring bills, as rows.
  ///
  /// Only `scheduled` instances: a posted one is already a real transaction and
  /// arrives through [ledgerMonthlyTransactions]'s posted half, and a skipped
  /// one is a decision the user made and does not want to see again.
  ///
  /// Filtered to the month here rather than in the DAO because the ledger's
  /// month view is what needs the slice; the instance table itself stays whole.
  MonthlyPendingTransactionsProvider._(
      {required MonthlyPendingTransactionsFamily super.from,
      required DateTime super.argument})
      : super(
          retry: null,
          name: r'monthlyPendingTransactionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlyPendingTransactionsHash();

  @override
  String toString() {
    return r'monthlyPendingTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TransactionTileUiModel>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<TransactionTileUiModel>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthlyPendingTransactions(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyPendingTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyPendingTransactionsHash() =>
    r'20b047a6c35129c7853911e05b06eb2c08689905';

/// The month's upcoming recurring bills, as rows.
///
/// Only `scheduled` instances: a posted one is already a real transaction and
/// arrives through [ledgerMonthlyTransactions]'s posted half, and a skipped
/// one is a decision the user made and does not want to see again.
///
/// Filtered to the month here rather than in the DAO because the ledger's
/// month view is what needs the slice; the instance table itself stays whole.

final class MonthlyPendingTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<TransactionTileUiModel>>,
            DateTime> {
  MonthlyPendingTransactionsFamily._()
      : super(
          retry: null,
          name: r'monthlyPendingTransactionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The month's upcoming recurring bills, as rows.
  ///
  /// Only `scheduled` instances: a posted one is already a real transaction and
  /// arrives through [ledgerMonthlyTransactions]'s posted half, and a skipped
  /// one is a decision the user made and does not want to see again.
  ///
  /// Filtered to the month here rather than in the DAO because the ledger's
  /// month view is what needs the slice; the instance table itself stays whole.

  MonthlyPendingTransactionsProvider call(
    DateTime month,
  ) =>
      MonthlyPendingTransactionsProvider._(argument: month, from: this);

  @override
  String toString() => r'monthlyPendingTransactionsProvider';
}

/// The set of months (normalized to the first of each month) that hold at
/// least one pending bill in the current currency.
///
/// The month picker marks these so an overdue bill is findable without paging
/// through every month (spec 006, US33). Scoped to the setting's currency,
/// like the rest of the ledger list.

@ProviderFor(pendingBillMonths)
final pendingBillMonthsProvider = PendingBillMonthsProvider._();

/// The set of months (normalized to the first of each month) that hold at
/// least one pending bill in the current currency.
///
/// The month picker marks these so an overdue bill is findable without paging
/// through every month (spec 006, US33). Scoped to the setting's currency,
/// like the rest of the ledger list.

final class PendingBillMonthsProvider extends $FunctionalProvider<
        AsyncValue<Set<DateTime>>, Set<DateTime>, Stream<Set<DateTime>>>
    with $FutureModifier<Set<DateTime>>, $StreamProvider<Set<DateTime>> {
  /// The set of months (normalized to the first of each month) that hold at
  /// least one pending bill in the current currency.
  ///
  /// The month picker marks these so an overdue bill is findable without paging
  /// through every month (spec 006, US33). Scoped to the setting's currency,
  /// like the rest of the ledger list.
  PendingBillMonthsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingBillMonthsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingBillMonthsHash();

  @$internal
  @override
  $StreamProviderElement<Set<DateTime>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Set<DateTime>> create(Ref ref) {
    return pendingBillMonths(ref);
  }
}

String _$pendingBillMonthsHash() => r'ead51495d0b7f9ac4da2ee13dcfac3ecc579a578';

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

@ProviderFor(ledgerMonthlyTransactions)
final ledgerMonthlyTransactionsProvider = LedgerMonthlyTransactionsFamily._();

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

final class LedgerMonthlyTransactionsProvider extends $FunctionalProvider<
        AsyncValue<List<LedgerDayGroup>>,
        List<LedgerDayGroup>,
        Stream<List<LedgerDayGroup>>>
    with
        $FutureModifier<List<LedgerDayGroup>>,
        $StreamProvider<List<LedgerDayGroup>> {
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
  LedgerMonthlyTransactionsProvider._(
      {required LedgerMonthlyTransactionsFamily super.from,
      required DateTime super.argument})
      : super(
          retry: null,
          name: r'ledgerMonthlyTransactionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerMonthlyTransactionsHash();

  @override
  String toString() {
    return r'ledgerMonthlyTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LedgerDayGroup>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<LedgerDayGroup>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return ledgerMonthlyTransactions(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LedgerMonthlyTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ledgerMonthlyTransactionsHash() =>
    r'c77464c85a3564ae7e1a7ffc2685ce301cbb39ad';

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

final class LedgerMonthlyTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LedgerDayGroup>>, DateTime> {
  LedgerMonthlyTransactionsFamily._()
      : super(
          retry: null,
          name: r'ledgerMonthlyTransactionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

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

  LedgerMonthlyTransactionsProvider call(
    DateTime month,
  ) =>
      LedgerMonthlyTransactionsProvider._(argument: month, from: this);

  @override
  String toString() => r'ledgerMonthlyTransactionsProvider';
}

/// The currency this ledger is scoped to.
///
/// The setting is the single source of truth for the ledger, search and
/// reports (spec 006). Accounts no longer decide: they are created in
/// whatever the preference was at the time and can therefore hold several
/// currencies at once, with no FX conversion to pick one. The ledger shows
/// the currency the user asked to see — and a setting with no accounts in it
/// is the empty state, not an error.

@ProviderFor(ledgerCurrency)
final ledgerCurrencyProvider = LedgerCurrencyProvider._();

/// The currency this ledger is scoped to.
///
/// The setting is the single source of truth for the ledger, search and
/// reports (spec 006). Accounts no longer decide: they are created in
/// whatever the preference was at the time and can therefore hold several
/// currencies at once, with no FX conversion to pick one. The ledger shows
/// the currency the user asked to see — and a setting with no accounts in it
/// is the empty state, not an error.

final class LedgerCurrencyProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  /// The currency this ledger is scoped to.
  ///
  /// The setting is the single source of truth for the ledger, search and
  /// reports (spec 006). Accounts no longer decide: they are created in
  /// whatever the preference was at the time and can therefore hold several
  /// currencies at once, with no FX conversion to pick one. The ledger shows
  /// the currency the user asked to see — and a setting with no accounts in it
  /// is the empty state, not an error.
  LedgerCurrencyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerCurrencyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerCurrencyHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return ledgerCurrency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$ledgerCurrencyHash() => r'29c690503fe4dd7447155bc183f62f208a073bcc';

/// The symbol the ledger writes next to an amount — the setting's currency,
/// for the same reason [ledgerCurrency] exists.
///
/// A provider rather than a constant so the timeline does not have to thread
/// it down: everything that needs it reads it here, at the layer that is
/// already converting the amounts it belongs to.

@ProviderFor(displayCurrencySymbol)
final displayCurrencySymbolProvider = DisplayCurrencySymbolProvider._();

/// The symbol the ledger writes next to an amount — the setting's currency,
/// for the same reason [ledgerCurrency] exists.
///
/// A provider rather than a constant so the timeline does not have to thread
/// it down: everything that needs it reads it here, at the layer that is
/// already converting the amounts it belongs to.

final class DisplayCurrencySymbolProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  /// The symbol the ledger writes next to an amount — the setting's currency,
  /// for the same reason [ledgerCurrency] exists.
  ///
  /// A provider rather than a constant so the timeline does not have to thread
  /// it down: everything that needs it reads it here, at the layer that is
  /// already converting the amounts it belongs to.
  DisplayCurrencySymbolProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'displayCurrencySymbolProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$displayCurrencySymbolHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return displayCurrencySymbol(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$displayCurrencySymbolHash() =>
    r'345dfe9a085bdcca305f7cd671d18431d36f721b';

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

@ProviderFor(ledgerMonthlySummary)
final ledgerMonthlySummaryProvider = LedgerMonthlySummaryFamily._();

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

final class LedgerMonthlySummaryProvider extends $FunctionalProvider<
        AsyncValue<MonthlySummaryUiModel>,
        MonthlySummaryUiModel,
        Stream<MonthlySummaryUiModel>>
    with
        $FutureModifier<MonthlySummaryUiModel>,
        $StreamProvider<MonthlySummaryUiModel> {
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
  LedgerMonthlySummaryProvider._(
      {required LedgerMonthlySummaryFamily super.from,
      required DateTime super.argument})
      : super(
          retry: null,
          name: r'ledgerMonthlySummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerMonthlySummaryHash();

  @override
  String toString() {
    return r'ledgerMonthlySummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<MonthlySummaryUiModel> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<MonthlySummaryUiModel> create(Ref ref) {
    final argument = this.argument as DateTime;
    return ledgerMonthlySummary(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LedgerMonthlySummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ledgerMonthlySummaryHash() =>
    r'3afe60153903b552f5366115691aa5ea606bd8ae';

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

final class LedgerMonthlySummaryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<MonthlySummaryUiModel>, DateTime> {
  LedgerMonthlySummaryFamily._()
      : super(
          retry: null,
          name: r'ledgerMonthlySummaryProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

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

  LedgerMonthlySummaryProvider call(
    DateTime month,
  ) =>
      LedgerMonthlySummaryProvider._(argument: month, from: this);

  @override
  String toString() => r'ledgerMonthlySummaryProvider';
}

/// Session-only count of overdue bills newly materialized at startup.
///
/// Kept purely in memory so dismissing hides the banner for the rest of the
/// session without persisting extra UI flags or re-prompting on already
/// materialized rows.

@ProviderFor(OverdueMaterializationCount)
final overdueMaterializationCountProvider =
    OverdueMaterializationCountProvider._();

/// Session-only count of overdue bills newly materialized at startup.
///
/// Kept purely in memory so dismissing hides the banner for the rest of the
/// session without persisting extra UI flags or re-prompting on already
/// materialized rows.
final class OverdueMaterializationCountProvider
    extends $NotifierProvider<OverdueMaterializationCount, int> {
  /// Session-only count of overdue bills newly materialized at startup.
  ///
  /// Kept purely in memory so dismissing hides the banner for the rest of the
  /// session without persisting extra UI flags or re-prompting on already
  /// materialized rows.
  OverdueMaterializationCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'overdueMaterializationCountProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$overdueMaterializationCountHash();

  @$internal
  @override
  OverdueMaterializationCount create() => OverdueMaterializationCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$overdueMaterializationCountHash() =>
    r'0b1044c3a6be7e7025f6f896e47b881d1a080807';

/// Session-only count of overdue bills newly materialized at startup.
///
/// Kept purely in memory so dismissing hides the banner for the rest of the
/// session without persisting extra UI flags or re-prompting on already
/// materialized rows.

abstract class _$OverdueMaterializationCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LedgerViewModel)
final ledgerViewModelProvider = LedgerViewModelProvider._();

final class LedgerViewModelProvider
    extends $NotifierProvider<LedgerViewModel, LedgerViewState> {
  LedgerViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ledgerViewModelProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ledgerViewModelHash();

  @$internal
  @override
  LedgerViewModel create() => LedgerViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LedgerViewState>(value),
    );
  }
}

String _$ledgerViewModelHash() => r'f112acc654a39f55d661a692c9cec1d15d88f82f';

abstract class _$LedgerViewModel extends $Notifier<LedgerViewState> {
  LedgerViewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LedgerViewState, LedgerViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<LedgerViewState, LedgerViewState>,
        LedgerViewState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
