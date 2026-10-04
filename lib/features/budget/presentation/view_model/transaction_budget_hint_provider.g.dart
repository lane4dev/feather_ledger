// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_budget_hint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionBudgetHint)
final transactionBudgetHintProvider = TransactionBudgetHintFamily._();

final class TransactionBudgetHintProvider extends $FunctionalProvider<
        AsyncValue<CategoryBudgetHint>,
        CategoryBudgetHint,
        Stream<CategoryBudgetHint>>
    with
        $FutureModifier<CategoryBudgetHint>,
        $StreamProvider<CategoryBudgetHint> {
  TransactionBudgetHintProvider._(
      {required TransactionBudgetHintFamily super.from,
      required ({
        String currencyCode,
        YearMonth month,
        String categoryId,
      })
          super.argument})
      : super(
          retry: null,
          name: r'transactionBudgetHintProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transactionBudgetHintHash();

  @override
  String toString() {
    return r'transactionBudgetHintProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<CategoryBudgetHint> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<CategoryBudgetHint> create(Ref ref) {
    final argument = this.argument as ({
      String currencyCode,
      YearMonth month,
      String categoryId,
    });
    return transactionBudgetHint(
      ref,
      currencyCode: argument.currencyCode,
      month: argument.month,
      categoryId: argument.categoryId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionBudgetHintProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionBudgetHintHash() =>
    r'6b67f16e734017c6e635025f484d75d39d5ee415';

final class TransactionBudgetHintFamily extends $Family
    with
        $FunctionalFamilyOverride<
            Stream<CategoryBudgetHint>,
            ({
              String currencyCode,
              YearMonth month,
              String categoryId,
            })> {
  TransactionBudgetHintFamily._()
      : super(
          retry: null,
          name: r'transactionBudgetHintProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  TransactionBudgetHintProvider call({
    required String currencyCode,
    required YearMonth month,
    required String categoryId,
  }) =>
      TransactionBudgetHintProvider._(argument: (
        currencyCode: currencyCode,
        month: month,
        categoryId: categoryId,
      ), from: this);

  @override
  String toString() => r'transactionBudgetHintProvider';
}
