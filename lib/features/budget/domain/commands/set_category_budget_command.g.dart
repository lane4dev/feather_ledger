// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_category_budget_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(setCategoryBudgetCommand)
final setCategoryBudgetCommandProvider = SetCategoryBudgetCommandProvider._();

final class SetCategoryBudgetCommandProvider extends $FunctionalProvider<
    SetCategoryBudgetCommand,
    SetCategoryBudgetCommand,
    SetCategoryBudgetCommand> with $Provider<SetCategoryBudgetCommand> {
  SetCategoryBudgetCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'setCategoryBudgetCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$setCategoryBudgetCommandHash();

  @$internal
  @override
  $ProviderElement<SetCategoryBudgetCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetCategoryBudgetCommand create(Ref ref) {
    return setCategoryBudgetCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetCategoryBudgetCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetCategoryBudgetCommand>(value),
    );
  }
}

String _$setCategoryBudgetCommandHash() =>
    r'c21f113d767561ccc365c9f5a25b90273385cb82';
