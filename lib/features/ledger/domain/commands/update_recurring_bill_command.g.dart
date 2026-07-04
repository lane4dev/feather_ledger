// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_recurring_bill_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updateRecurringBillCommand)
final updateRecurringBillCommandProvider =
    UpdateRecurringBillCommandProvider._();

final class UpdateRecurringBillCommandProvider extends $FunctionalProvider<
    UpdateRecurringBillCommand,
    UpdateRecurringBillCommand,
    UpdateRecurringBillCommand> with $Provider<UpdateRecurringBillCommand> {
  UpdateRecurringBillCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'updateRecurringBillCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$updateRecurringBillCommandHash();

  @$internal
  @override
  $ProviderElement<UpdateRecurringBillCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateRecurringBillCommand create(Ref ref) {
    return updateRecurringBillCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateRecurringBillCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateRecurringBillCommand>(value),
    );
  }
}

String _$updateRecurringBillCommandHash() =>
    r'94199565cb7afbd2bf5f340be74ba706be5e34d5';
