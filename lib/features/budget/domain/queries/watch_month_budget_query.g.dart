// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_month_budget_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchMonthBudgetQuery)
final watchMonthBudgetQueryProvider = WatchMonthBudgetQueryProvider._();

final class WatchMonthBudgetQueryProvider extends $FunctionalProvider<
    WatchMonthBudgetQuery,
    WatchMonthBudgetQuery,
    WatchMonthBudgetQuery> with $Provider<WatchMonthBudgetQuery> {
  WatchMonthBudgetQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'watchMonthBudgetQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$watchMonthBudgetQueryHash();

  @$internal
  @override
  $ProviderElement<WatchMonthBudgetQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMonthBudgetQuery create(Ref ref) {
    return watchMonthBudgetQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMonthBudgetQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMonthBudgetQuery>(value),
    );
  }
}

String _$watchMonthBudgetQueryHash() =>
    r'86cde721faa4f1c3ae5a09a5926d1f722860b0f6';
