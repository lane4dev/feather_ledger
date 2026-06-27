// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_export_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionExportService)
final transactionExportServiceProvider = TransactionExportServiceProvider._();

final class TransactionExportServiceProvider extends $FunctionalProvider<
        AsyncValue<TransactionExportService>,
        TransactionExportService,
        FutureOr<TransactionExportService>>
    with
        $FutureModifier<TransactionExportService>,
        $FutureProvider<TransactionExportService> {
  TransactionExportServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'transactionExportServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transactionExportServiceHash();

  @$internal
  @override
  $FutureProviderElement<TransactionExportService> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TransactionExportService> create(Ref ref) {
    return transactionExportService(ref);
  }
}

String _$transactionExportServiceHash() =>
    r'3e2cfce3563dd3069227b8b579bd1b390d566122';
