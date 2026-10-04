// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clear_category_budget_command.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clearCategoryBudgetCommand)
final clearCategoryBudgetCommandProvider =
    ClearCategoryBudgetCommandProvider._();

final class ClearCategoryBudgetCommandProvider extends $FunctionalProvider<
    ClearCategoryBudgetCommand,
    ClearCategoryBudgetCommand,
    ClearCategoryBudgetCommand> with $Provider<ClearCategoryBudgetCommand> {
  ClearCategoryBudgetCommandProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'clearCategoryBudgetCommandProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$clearCategoryBudgetCommandHash();

  @$internal
  @override
  $ProviderElement<ClearCategoryBudgetCommand> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClearCategoryBudgetCommand create(Ref ref) {
    return clearCategoryBudgetCommand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClearCategoryBudgetCommand value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClearCategoryBudgetCommand>(value),
    );
  }
}

String _$clearCategoryBudgetCommandHash() =>
    r'3a42e11484580cd4bfe660c5c1e3f9c58adf3618';
