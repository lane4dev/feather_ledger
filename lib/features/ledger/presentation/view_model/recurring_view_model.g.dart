// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The write actions for recurring bills (spec 004, US2).
///
/// There is no state here: the bills themselves reach the screen through
/// `ledgerMonthlyTransactionsProvider`, which merges them into the month
/// list, and the series list is gone. What is left is the three things a
/// person can *do* to a pending bill.

@ProviderFor(RecurringViewModel)
final recurringViewModelProvider = RecurringViewModelProvider._();

/// The write actions for recurring bills (spec 004, US2).
///
/// There is no state here: the bills themselves reach the screen through
/// `ledgerMonthlyTransactionsProvider`, which merges them into the month
/// list, and the series list is gone. What is left is the three things a
/// person can *do* to a pending bill.
final class RecurringViewModelProvider
    extends $NotifierProvider<RecurringViewModel, void> {
  /// The write actions for recurring bills (spec 004, US2).
  ///
  /// There is no state here: the bills themselves reach the screen through
  /// `ledgerMonthlyTransactionsProvider`, which merges them into the month
  /// list, and the series list is gone. What is left is the three things a
  /// person can *do* to a pending bill.
  RecurringViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recurringViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recurringViewModelHash();

  @$internal
  @override
  RecurringViewModel create() => RecurringViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$recurringViewModelHash() =>
    r'06cc2596aacd3fc0d4d2a559df27038af61f10c6';

/// The write actions for recurring bills (spec 004, US2).
///
/// There is no state here: the bills themselves reach the screen through
/// `ledgerMonthlyTransactionsProvider`, which merges them into the month
/// list, and the series list is gone. What is left is the three things a
/// person can *do* to a pending bill.

abstract class _$RecurringViewModel extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
