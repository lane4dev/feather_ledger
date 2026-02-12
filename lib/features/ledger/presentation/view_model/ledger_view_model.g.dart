// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ledgerMonthlyTransactionsHash() =>
    r'ab76eeb927e89a8bf901fb776d9b642cafde9e08';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [ledgerMonthlyTransactions].
@ProviderFor(ledgerMonthlyTransactions)
const ledgerMonthlyTransactionsProvider = LedgerMonthlyTransactionsFamily();

/// See also [ledgerMonthlyTransactions].
class LedgerMonthlyTransactionsFamily
    extends Family<AsyncValue<Map<DateTime, List<TransactionTileUiModel>>>> {
  /// See also [ledgerMonthlyTransactions].
  const LedgerMonthlyTransactionsFamily();

  /// See also [ledgerMonthlyTransactions].
  LedgerMonthlyTransactionsProvider call(
    DateTime month,
  ) {
    return LedgerMonthlyTransactionsProvider(
      month,
    );
  }

  @override
  LedgerMonthlyTransactionsProvider getProviderOverride(
    covariant LedgerMonthlyTransactionsProvider provider,
  ) {
    return call(
      provider.month,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ledgerMonthlyTransactionsProvider';
}

/// See also [ledgerMonthlyTransactions].
class LedgerMonthlyTransactionsProvider extends AutoDisposeStreamProvider<
    Map<DateTime, List<TransactionTileUiModel>>> {
  /// See also [ledgerMonthlyTransactions].
  LedgerMonthlyTransactionsProvider(
    DateTime month,
  ) : this._internal(
          (ref) => ledgerMonthlyTransactions(
            ref as LedgerMonthlyTransactionsRef,
            month,
          ),
          from: ledgerMonthlyTransactionsProvider,
          name: r'ledgerMonthlyTransactionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ledgerMonthlyTransactionsHash,
          dependencies: LedgerMonthlyTransactionsFamily._dependencies,
          allTransitiveDependencies:
              LedgerMonthlyTransactionsFamily._allTransitiveDependencies,
          month: month,
        );

  LedgerMonthlyTransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
  }) : super.internal();

  final DateTime month;

  @override
  Override overrideWith(
    Stream<Map<DateTime, List<TransactionTileUiModel>>> Function(
            LedgerMonthlyTransactionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LedgerMonthlyTransactionsProvider._internal(
        (ref) => create(ref as LedgerMonthlyTransactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<Map<DateTime, List<TransactionTileUiModel>>>
      createElement() {
    return _LedgerMonthlyTransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LedgerMonthlyTransactionsProvider && other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LedgerMonthlyTransactionsRef on AutoDisposeStreamProviderRef<
    Map<DateTime, List<TransactionTileUiModel>>> {
  /// The parameter `month` of this provider.
  DateTime get month;
}

class _LedgerMonthlyTransactionsProviderElement
    extends AutoDisposeStreamProviderElement<
        Map<DateTime, List<TransactionTileUiModel>>>
    with LedgerMonthlyTransactionsRef {
  _LedgerMonthlyTransactionsProviderElement(super.provider);

  @override
  DateTime get month => (origin as LedgerMonthlyTransactionsProvider).month;
}

String _$ledgerViewModelHash() => r'4d320ea1a0fb00594be9313be323e39380ddf5da';

/// See also [LedgerViewModel].
@ProviderFor(LedgerViewModel)
final ledgerViewModelProvider =
    NotifierProvider<LedgerViewModel, LedgerViewState>.internal(
  LedgerViewModel.new,
  name: r'ledgerViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ledgerViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LedgerViewModel = Notifier<LedgerViewState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
