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
/// Pending bills are merged into the same day-grouped map so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Within a day the posted rows stay first — the list reads as history and
/// then as forecast.

@ProviderFor(ledgerMonthlyTransactions)
final ledgerMonthlyTransactionsProvider = LedgerMonthlyTransactionsFamily._();

/// The month's ledger rows: what happened, then what is coming.
///
/// Pending bills are merged into the same day-grouped map so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Within a day the posted rows stay first — the list reads as history and
/// then as forecast.

final class LedgerMonthlyTransactionsProvider extends $FunctionalProvider<
        AsyncValue<Map<DateTime, List<TransactionTileUiModel>>>,
        Map<DateTime, List<TransactionTileUiModel>>,
        Stream<Map<DateTime, List<TransactionTileUiModel>>>>
    with
        $FutureModifier<Map<DateTime, List<TransactionTileUiModel>>>,
        $StreamProvider<Map<DateTime, List<TransactionTileUiModel>>> {
  /// The month's ledger rows: what happened, then what is coming.
  ///
  /// Pending bills are merged into the same day-grouped map so a bill dated the
  /// 1st sits under the 1st, beside whatever real transactions share that day.
  /// Within a day the posted rows stay first — the list reads as history and
  /// then as forecast.
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
  $StreamProviderElement<Map<DateTime, List<TransactionTileUiModel>>>
      $createElement($ProviderPointer pointer) =>
          $StreamProviderElement(pointer);

  @override
  Stream<Map<DateTime, List<TransactionTileUiModel>>> create(Ref ref) {
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
    r'49143c27ef3125c63a8a6c0b096d6de81068e1cb';

/// The month's ledger rows: what happened, then what is coming.
///
/// Pending bills are merged into the same day-grouped map so a bill dated the
/// 1st sits under the 1st, beside whatever real transactions share that day.
/// Within a day the posted rows stay first — the list reads as history and
/// then as forecast.

final class LedgerMonthlyTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            Stream<Map<DateTime, List<TransactionTileUiModel>>>, DateTime> {
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
  /// Pending bills are merged into the same day-grouped map so a bill dated the
  /// 1st sits under the 1st, beside whatever real transactions share that day.
  /// Within a day the posted rows stay first — the list reads as history and
  /// then as forecast.

  LedgerMonthlyTransactionsProvider call(
    DateTime month,
  ) =>
      LedgerMonthlyTransactionsProvider._(argument: month, from: this);

  @override
  String toString() => r'ledgerMonthlyTransactionsProvider';
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

String _$ledgerViewModelHash() => r'8db85a524c3acd72774078426af7ca250ec0e7ce';

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
