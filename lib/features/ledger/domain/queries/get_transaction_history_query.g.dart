// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_transaction_history_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getTransactionHistoryQuery)
final getTransactionHistoryQueryProvider =
    GetTransactionHistoryQueryProvider._();

final class GetTransactionHistoryQueryProvider extends $FunctionalProvider<
    GetTransactionHistoryQuery,
    GetTransactionHistoryQuery,
    GetTransactionHistoryQuery> with $Provider<GetTransactionHistoryQuery> {
  GetTransactionHistoryQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getTransactionHistoryQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTransactionHistoryQueryHash();

  @$internal
  @override
  $ProviderElement<GetTransactionHistoryQuery> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTransactionHistoryQuery create(Ref ref) {
    return getTransactionHistoryQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTransactionHistoryQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTransactionHistoryQuery>(value),
    );
  }
}

String _$getTransactionHistoryQueryHash() =>
    r'ab04e79af29f12a9dde677bdd3a2e0a21cf49fed';

@ProviderFor(getTransactionHistory)
final getTransactionHistoryProvider = GetTransactionHistoryFamily._();

final class GetTransactionHistoryProvider extends $FunctionalProvider<
        AsyncValue<List<TransactionHistoryEntry>>,
        List<TransactionHistoryEntry>,
        FutureOr<List<TransactionHistoryEntry>>>
    with
        $FutureModifier<List<TransactionHistoryEntry>>,
        $FutureProvider<List<TransactionHistoryEntry>> {
  GetTransactionHistoryProvider._(
      {required GetTransactionHistoryFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'getTransactionHistoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTransactionHistoryHash();

  @override
  String toString() {
    return r'getTransactionHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TransactionHistoryEntry>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<TransactionHistoryEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return getTransactionHistory(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GetTransactionHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getTransactionHistoryHash() =>
    r'f848194572a613a45041b7cf7629bc6e071451b2';

final class GetTransactionHistoryFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<TransactionHistoryEntry>>,
            String> {
  GetTransactionHistoryFamily._()
      : super(
          retry: null,
          name: r'getTransactionHistoryProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  GetTransactionHistoryProvider call(
    String transactionId,
  ) =>
      GetTransactionHistoryProvider._(argument: transactionId, from: this);

  @override
  String toString() => r'getTransactionHistoryProvider';
}
