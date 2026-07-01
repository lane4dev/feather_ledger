// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_recurring_bill_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deleteRecurringBillCommand)
final deleteRecurringBillCommandProvider =
    DeleteRecurringBillCommandProvider._();

final class DeleteRecurringBillCommandProvider extends $FunctionalProvider<
    DeleteRecurringBillCommand,
    DeleteRecurringBillCommand,
    DeleteRecurringBillCommand> with $Provider<DeleteRecurringBillCommand> {
  DeleteRecurringBillCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deleteRecurringBillCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deleteRecurringBillCommandHash();

  @$internal
  @override
  $ProviderElement<DeleteRecurringBillCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteRecurringBillCommand create(Ref ref) {
    return deleteRecurringBillCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteRecurringBillCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteRecurringBillCommand>(value),
    );
  }
}

String _$deleteRecurringBillCommandHash() =>
    r'9088408c08f1955dd8bafc793b6ba4b8564d60a1';
