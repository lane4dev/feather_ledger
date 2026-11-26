// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_form_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The form's state and the rules that read it.
///
/// The entry being corrected is the provider's *argument*, not something
/// seeded afterwards: a notifier may not modify a provider from `initState`,
/// and a form that filled itself in on the next frame would flash empty first.
/// The argument never changes while the form is open, which is the difference
/// between this family and the one [SearchViewModel] argues against — that one
/// took the query, which changes on every keystroke.
///
/// [build] deliberately watches nothing else. Watching the account or category
/// lists here would look harmless and be the opposite: every emission of those
/// streams re-runs `build` and wipes a half-filled form. The rules that need
/// those lists — which accounts a picker may offer, where a transfer may land
/// — are pure methods on [TransactionFormViewState], fed by the screen, which
/// watches those providers anyway.
///
/// Known ceiling: the family key is the tile itself, which has no `==`, so two
/// forms opened for "a new entry" at the same time would share one state.
/// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
/// push each other — and the fix, if something ever can, is a nested
/// `ProviderScope` per form.

@ProviderFor(TransactionFormViewModel)
final transactionFormViewModelProvider = TransactionFormViewModelFamily._();

/// The form's state and the rules that read it.
///
/// The entry being corrected is the provider's *argument*, not something
/// seeded afterwards: a notifier may not modify a provider from `initState`,
/// and a form that filled itself in on the next frame would flash empty first.
/// The argument never changes while the form is open, which is the difference
/// between this family and the one [SearchViewModel] argues against — that one
/// took the query, which changes on every keystroke.
///
/// [build] deliberately watches nothing else. Watching the account or category
/// lists here would look harmless and be the opposite: every emission of those
/// streams re-runs `build` and wipes a half-filled form. The rules that need
/// those lists — which accounts a picker may offer, where a transfer may land
/// — are pure methods on [TransactionFormViewState], fed by the screen, which
/// watches those providers anyway.
///
/// Known ceiling: the family key is the tile itself, which has no `==`, so two
/// forms opened for "a new entry" at the same time would share one state.
/// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
/// push each other — and the fix, if something ever can, is a nested
/// `ProviderScope` per form.
final class TransactionFormViewModelProvider extends $NotifierProvider<
    TransactionFormViewModel, TransactionFormViewState> {
  /// The form's state and the rules that read it.
  ///
  /// The entry being corrected is the provider's *argument*, not something
  /// seeded afterwards: a notifier may not modify a provider from `initState`,
  /// and a form that filled itself in on the next frame would flash empty first.
  /// The argument never changes while the form is open, which is the difference
  /// between this family and the one [SearchViewModel] argues against — that one
  /// took the query, which changes on every keystroke.
  ///
  /// [build] deliberately watches nothing else. Watching the account or category
  /// lists here would look harmless and be the opposite: every emission of those
  /// streams re-runs `build` and wipes a half-filled form. The rules that need
  /// those lists — which accounts a picker may offer, where a transfer may land
  /// — are pure methods on [TransactionFormViewState], fed by the screen, which
  /// watches those providers anyway.
  ///
  /// Known ceiling: the family key is the tile itself, which has no `==`, so two
  /// forms opened for "a new entry" at the same time would share one state.
  /// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
  /// push each other — and the fix, if something ever can, is a nested
  /// `ProviderScope` per form.
  TransactionFormViewModelProvider._(
      {required TransactionFormViewModelFamily super.from,
      required TransactionTileUiModel? super.argument})
      : super(
          retry: null,
          name: r'transactionFormViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transactionFormViewModelHash();

  @override
  String toString() {
    return r'transactionFormViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionFormViewModel create() => TransactionFormViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFormViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionFormViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFormViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionFormViewModelHash() =>
    r'6bccb3746cb9379858a949327a320acd09c89dbf';

/// The form's state and the rules that read it.
///
/// The entry being corrected is the provider's *argument*, not something
/// seeded afterwards: a notifier may not modify a provider from `initState`,
/// and a form that filled itself in on the next frame would flash empty first.
/// The argument never changes while the form is open, which is the difference
/// between this family and the one [SearchViewModel] argues against — that one
/// took the query, which changes on every keystroke.
///
/// [build] deliberately watches nothing else. Watching the account or category
/// lists here would look harmless and be the opposite: every emission of those
/// streams re-runs `build` and wipes a half-filled form. The rules that need
/// those lists — which accounts a picker may offer, where a transfer may land
/// — are pure methods on [TransactionFormViewState], fed by the screen, which
/// watches those providers anyway.
///
/// Known ceiling: the family key is the tile itself, which has no `==`, so two
/// forms opened for "a new entry" at the same time would share one state.
/// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
/// push each other — and the fix, if something ever can, is a nested
/// `ProviderScope` per form.

final class TransactionFormViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
            TransactionFormViewModel,
            TransactionFormViewState,
            TransactionFormViewState,
            TransactionFormViewState,
            TransactionTileUiModel?> {
  TransactionFormViewModelFamily._()
      : super(
          retry: null,
          name: r'transactionFormViewModelProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The form's state and the rules that read it.
  ///
  /// The entry being corrected is the provider's *argument*, not something
  /// seeded afterwards: a notifier may not modify a provider from `initState`,
  /// and a form that filled itself in on the next frame would flash empty first.
  /// The argument never changes while the form is open, which is the difference
  /// between this family and the one [SearchViewModel] argues against — that one
  /// took the query, which changes on every keystroke.
  ///
  /// [build] deliberately watches nothing else. Watching the account or category
  /// lists here would look harmless and be the opposite: every emission of those
  /// streams re-runs `build` and wipes a half-filled form. The rules that need
  /// those lists — which accounts a picker may offer, where a transfer may land
  /// — are pure methods on [TransactionFormViewState], fed by the screen, which
  /// watches those providers anyway.
  ///
  /// Known ceiling: the family key is the tile itself, which has no `==`, so two
  /// forms opened for "a new entry" at the same time would share one state.
  /// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
  /// push each other — and the fix, if something ever can, is a nested
  /// `ProviderScope` per form.

  TransactionFormViewModelProvider call(
    TransactionTileUiModel? original,
  ) =>
      TransactionFormViewModelProvider._(argument: original, from: this);

  @override
  String toString() => r'transactionFormViewModelProvider';
}

/// The form's state and the rules that read it.
///
/// The entry being corrected is the provider's *argument*, not something
/// seeded afterwards: a notifier may not modify a provider from `initState`,
/// and a form that filled itself in on the next frame would flash empty first.
/// The argument never changes while the form is open, which is the difference
/// between this family and the one [SearchViewModel] argues against — that one
/// took the query, which changes on every keystroke.
///
/// [build] deliberately watches nothing else. Watching the account or category
/// lists here would look harmless and be the opposite: every emission of those
/// streams re-runs `build` and wipes a half-filled form. The rules that need
/// those lists — which accounts a picker may offer, where a transfer may land
/// — are pure methods on [TransactionFormViewState], fed by the screen, which
/// watches those providers anyway.
///
/// Known ceiling: the family key is the tile itself, which has no `==`, so two
/// forms opened for "a new entry" at the same time would share one state.
/// Nothing in the app can reach that — `/ledger/add` and `/ledger/edit` cannot
/// push each other — and the fix, if something ever can, is a nested
/// `ProviderScope` per form.

abstract class _$TransactionFormViewModel
    extends $Notifier<TransactionFormViewState> {
  late final _$args = ref.$arg as TransactionTileUiModel?;
  TransactionTileUiModel? get original => _$args;

  TransactionFormViewState build(
    TransactionTileUiModel? original,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<TransactionFormViewState, TransactionFormViewState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<TransactionFormViewState, TransactionFormViewState>,
        TransactionFormViewState,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
