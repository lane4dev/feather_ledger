// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ledgerTransactionsHash() =>
    r'b7b91ed5d63496a935e98dce39b4585cdd6bae7b';

/// See also [ledgerTransactions].
@ProviderFor(ledgerTransactions)
final ledgerTransactionsProvider =
    AutoDisposeStreamProvider<List<TransactionEntity>>.internal(
  ledgerTransactions,
  name: r'ledgerTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ledgerTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LedgerTransactionsRef
    = AutoDisposeStreamProviderRef<List<TransactionEntity>>;
String _$ledgerSummaryHash() => r'17c4579597e3b7a6aaf658961d707ac8fb06cbff';

/// See also [ledgerSummary].
@ProviderFor(ledgerSummary)
final ledgerSummaryProvider =
    AutoDisposeStreamProvider<MonthlySummary>.internal(
  ledgerSummary,
  name: r'ledgerSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ledgerSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LedgerSummaryRef = AutoDisposeStreamProviderRef<MonthlySummary>;
String _$dailyTransactionsHash() => r'fbede27cda443e3a6cb18f7eb6b22c901e06c98f';

/// See also [dailyTransactions].
@ProviderFor(dailyTransactions)
final dailyTransactionsProvider =
    AutoDisposeFutureProvider<Map<DateTime, List<TransactionEntity>>>.internal(
  dailyTransactions,
  name: r'dailyTransactionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyTransactionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DailyTransactionsRef
    = AutoDisposeFutureProviderRef<Map<DateTime, List<TransactionEntity>>>;
String _$selectedDateHash() => r'cc9b319722e2f967ffe36ff1184e0e14a6d96cf6';

/// See also [SelectedDate].
@ProviderFor(SelectedDate)
final selectedDateProvider =
    AutoDisposeNotifierProvider<SelectedDate, DateTime>.internal(
  SelectedDate.new,
  name: r'selectedDateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$selectedDateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedDate = AutoDisposeNotifier<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
