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
    r'4ebe5b9af56be0078f1a772aaec2a93729745940';

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

/// The month's ledger rows: what happened, then what is coming.
///
/// Pending bills are merged into the same day grouping so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Within a day the posted rows stay first — the list reads as history and
/// then as forecast.
///
/// The grouping and each day's totals are built here rather than in the
/// timeline, which is the only place that knows the display currency without
/// being told.

@ProviderFor(ledgerMonthlyTransactions)
final ledgerMonthlyTransactionsProvider = LedgerMonthlyTransactionsFamily._();

/// The month's ledger rows: what happened, then what is coming.
///
/// Pending bills are merged into the same day grouping so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Within a day the posted rows stay first — the list reads as history and
/// then as forecast.
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
  /// The month's ledger rows: what happened, then what is coming.
  ///
  /// Pending bills are merged into the same day grouping so a bill dated the
  /// 1st sits under the 1st, beside whatever real transactions share that day.
  /// Within a day the posted rows stay first — the list reads as history and
  /// then as forecast.
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
    r'0c120c820b286762c95fa4439334af0a294e46a1';

/// The month's ledger rows: what happened, then what is coming.
///
/// Pending bills are merged into the same day grouping so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Within a day the posted rows stay first — the list reads as history and
/// then as forecast.
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

  /// The month's ledger rows: what happened, then what is coming.
  ///
  /// Pending bills are merged into the same day grouping so a bill dated the
  /// 1st sits under the 1st, beside whatever real transactions share that day.
  /// Within a day the posted rows stay first — the list reads as history and
  /// then as forecast.
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

/// The currency this ledger is actually in.
///
/// **Not the same question as the display preference.** Every account is
/// created in whatever the preference was at the time, and there is no FX
/// conversion anywhere, so a preference that has since moved on describes a
/// currency the accounts are not in. Filtering the header's totals by it then
/// matches nothing and the ledger reports zeroes while holding money — which
/// is what happened on a zh-locale install, where the seeded USD accounts met
/// a preference resolved to CNY.
///
/// So: the accounts decide, and a ledger with one currency (the normal case,
/// since the form forces the current one) reports that currency whatever the
/// preference says. A genuinely mixed ledger has no single answer without FX,
/// so it falls back to the preference and reports that part of itself.

@ProviderFor(ledgerCurrency)
final ledgerCurrencyProvider = LedgerCurrencyProvider._();

/// The currency this ledger is actually in.
///
/// **Not the same question as the display preference.** Every account is
/// created in whatever the preference was at the time, and there is no FX
/// conversion anywhere, so a preference that has since moved on describes a
/// currency the accounts are not in. Filtering the header's totals by it then
/// matches nothing and the ledger reports zeroes while holding money — which
/// is what happened on a zh-locale install, where the seeded USD accounts met
/// a preference resolved to CNY.
///
/// So: the accounts decide, and a ledger with one currency (the normal case,
/// since the form forces the current one) reports that currency whatever the
/// preference says. A genuinely mixed ledger has no single answer without FX,
/// so it falls back to the preference and reports that part of itself.

final class LedgerCurrencyProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  /// The currency this ledger is actually in.
  ///
  /// **Not the same question as the display preference.** Every account is
  /// created in whatever the preference was at the time, and there is no FX
  /// conversion anywhere, so a preference that has since moved on describes a
  /// currency the accounts are not in. Filtering the header's totals by it then
  /// matches nothing and the ledger reports zeroes while holding money — which
  /// is what happened on a zh-locale install, where the seeded USD accounts met
  /// a preference resolved to CNY.
  ///
  /// So: the accounts decide, and a ledger with one currency (the normal case,
  /// since the form forces the current one) reports that currency whatever the
  /// preference says. A genuinely mixed ledger has no single answer without FX,
  /// so it falls back to the preference and reports that part of itself.
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

String _$ledgerCurrencyHash() => r'3a22e7d96f9d5a77c831d03e2d1bf4d61d216328';

/// The symbol the ledger writes next to an amount — the ledger's own currency,
/// for the same reason [ledgerCurrency] exists.
///
/// A provider rather than a constant so the timeline does not have to thread
/// it down: everything that needs it reads it here, at the layer that is
/// already converting the amounts it belongs to.

@ProviderFor(displayCurrencySymbol)
final displayCurrencySymbolProvider = DisplayCurrencySymbolProvider._();

/// The symbol the ledger writes next to an amount — the ledger's own currency,
/// for the same reason [ledgerCurrency] exists.
///
/// A provider rather than a constant so the timeline does not have to thread
/// it down: everything that needs it reads it here, at the layer that is
/// already converting the amounts it belongs to.

final class DisplayCurrencySymbolProvider
    extends $FunctionalProvider<String, String, String> with $Provider<String> {
  /// The symbol the ledger writes next to an amount — the ledger's own currency,
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
/// **both of its inputs move and one of them arrives late.** The month moves
/// by definition; the currency is derived from the accounts, and while they
/// are still loading there is no ledger currency yet, so the first answer is
/// the display preference — and before that, the built-in default.
///
/// A subscription that read the currency once and kept it filtered every
/// account out the moment the ledger settled on a different one: a fresh
/// install on a zh locale captured USD at first frame and then opened its
/// first account in CNY, so the header read `$0.00` over a ledger holding
/// ¥1000. Income and expense were wrong the same way, for the same reason —
/// the snapshot rows are filtered by that code too.
///
/// The only thing that re-read it was changing the month, which is why
/// swiping a month away and back appeared to fix it. `ref.watch` makes the
/// currency a dependency Riverpod can see, so it re-subscribes by itself.

@ProviderFor(ledgerMonthlySummary)
final ledgerMonthlySummaryProvider = LedgerMonthlySummaryFamily._();

/// The header's three figures for one month, in the ledger's own currency.
///
/// A provider rather than a subscription held by [LedgerViewModel], because
/// **both of its inputs move and one of them arrives late.** The month moves
/// by definition; the currency is derived from the accounts, and while they
/// are still loading there is no ledger currency yet, so the first answer is
/// the display preference — and before that, the built-in default.
///
/// A subscription that read the currency once and kept it filtered every
/// account out the moment the ledger settled on a different one: a fresh
/// install on a zh locale captured USD at first frame and then opened its
/// first account in CNY, so the header read `$0.00` over a ledger holding
/// ¥1000. Income and expense were wrong the same way, for the same reason —
/// the snapshot rows are filtered by that code too.
///
/// The only thing that re-read it was changing the month, which is why
/// swiping a month away and back appeared to fix it. `ref.watch` makes the
/// currency a dependency Riverpod can see, so it re-subscribes by itself.

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
  /// **both of its inputs move and one of them arrives late.** The month moves
  /// by definition; the currency is derived from the accounts, and while they
  /// are still loading there is no ledger currency yet, so the first answer is
  /// the display preference — and before that, the built-in default.
  ///
  /// A subscription that read the currency once and kept it filtered every
  /// account out the moment the ledger settled on a different one: a fresh
  /// install on a zh locale captured USD at first frame and then opened its
  /// first account in CNY, so the header read `$0.00` over a ledger holding
  /// ¥1000. Income and expense were wrong the same way, for the same reason —
  /// the snapshot rows are filtered by that code too.
  ///
  /// The only thing that re-read it was changing the month, which is why
  /// swiping a month away and back appeared to fix it. `ref.watch` makes the
  /// currency a dependency Riverpod can see, so it re-subscribes by itself.
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
/// **both of its inputs move and one of them arrives late.** The month moves
/// by definition; the currency is derived from the accounts, and while they
/// are still loading there is no ledger currency yet, so the first answer is
/// the display preference — and before that, the built-in default.
///
/// A subscription that read the currency once and kept it filtered every
/// account out the moment the ledger settled on a different one: a fresh
/// install on a zh locale captured USD at first frame and then opened its
/// first account in CNY, so the header read `$0.00` over a ledger holding
/// ¥1000. Income and expense were wrong the same way, for the same reason —
/// the snapshot rows are filtered by that code too.
///
/// The only thing that re-read it was changing the month, which is why
/// swiping a month away and back appeared to fix it. `ref.watch` makes the
/// currency a dependency Riverpod can see, so it re-subscribes by itself.

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
  /// **both of its inputs move and one of them arrives late.** The month moves
  /// by definition; the currency is derived from the accounts, and while they
  /// are still loading there is no ledger currency yet, so the first answer is
  /// the display preference — and before that, the built-in default.
  ///
  /// A subscription that read the currency once and kept it filtered every
  /// account out the moment the ledger settled on a different one: a fresh
  /// install on a zh locale captured USD at first frame and then opened its
  /// first account in CNY, so the header read `$0.00` over a ledger holding
  /// ¥1000. Income and expense were wrong the same way, for the same reason —
  /// the snapshot rows are filtered by that code too.
  ///
  /// The only thing that re-read it was changing the month, which is why
  /// swiping a month away and back appeared to fix it. `ref.watch` makes the
  /// currency a dependency Riverpod can see, so it re-subscribes by itself.

  LedgerMonthlySummaryProvider call(
    DateTime month,
  ) =>
      LedgerMonthlySummaryProvider._(argument: month, from: this);

  @override
  String toString() => r'ledgerMonthlySummaryProvider';
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

String _$ledgerViewModelHash() => r'91767e7bb7f04cf1988b0fa987fce55c3c31dce6';

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
