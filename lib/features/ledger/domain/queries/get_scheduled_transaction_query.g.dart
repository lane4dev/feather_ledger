// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_scheduled_transaction_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getScheduledTransactionQuery)
final getScheduledTransactionQueryProvider =
    GetScheduledTransactionQueryProvider._();

final class GetScheduledTransactionQueryProvider extends $FunctionalProvider<
    GetScheduledTransactionQuery,
    GetScheduledTransactionQuery,
    GetScheduledTransactionQuery> with $Provider<GetScheduledTransactionQuery> {
  GetScheduledTransactionQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getScheduledTransactionQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getScheduledTransactionQueryHash();

  @$internal
  @override
  $ProviderElement<GetScheduledTransactionQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetScheduledTransactionQuery create(Ref ref) {
    return getScheduledTransactionQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetScheduledTransactionQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetScheduledTransactionQuery>(value),
    );
  }
}

String _$getScheduledTransactionQueryHash() =>
    r'57069d0d28ae443251699da5773bc79f3dde3581';
