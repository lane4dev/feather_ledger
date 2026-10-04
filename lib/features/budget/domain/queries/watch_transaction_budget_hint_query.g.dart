// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_transaction_budget_hint_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchTransactionBudgetHintQuery)
final watchTransactionBudgetHintQueryProvider =
    WatchTransactionBudgetHintQueryProvider._();

final class WatchTransactionBudgetHintQueryProvider extends $FunctionalProvider<
        WatchTransactionBudgetHintQuery,
        WatchTransactionBudgetHintQuery,
        WatchTransactionBudgetHintQuery>
    with $Provider<WatchTransactionBudgetHintQuery> {
  WatchTransactionBudgetHintQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchTransactionBudgetHintQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchTransactionBudgetHintQueryHash();

  @$internal
  @override
  $ProviderElement<WatchTransactionBudgetHintQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchTransactionBudgetHintQuery create(Ref ref) {
    return watchTransactionBudgetHintQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTransactionBudgetHintQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<WatchTransactionBudgetHintQuery>(value),
    );
  }
}

String _$watchTransactionBudgetHintQueryHash() =>
    r'ee1949b53e9fefa00cf5d2983fa890ef94700591';
