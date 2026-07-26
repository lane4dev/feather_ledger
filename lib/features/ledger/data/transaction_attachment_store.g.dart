// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_attachment_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionAttachmentStore)
final transactionAttachmentStoreProvider =
    TransactionAttachmentStoreProvider._();

final class TransactionAttachmentStoreProvider extends $FunctionalProvider<
    TransactionAttachmentStore,
    TransactionAttachmentStore,
    TransactionAttachmentStore> with $Provider<TransactionAttachmentStore> {
  TransactionAttachmentStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'transactionAttachmentStoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transactionAttachmentStoreHash();

  @$internal
  @override
  $ProviderElement<TransactionAttachmentStore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TransactionAttachmentStore create(Ref ref) {
    return transactionAttachmentStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionAttachmentStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionAttachmentStore>(value),
    );
  }
}

String _$transactionAttachmentStoreHash() =>
    r'3af1f4bbb2b045d9b0da29dea5b24eca902077b8';
