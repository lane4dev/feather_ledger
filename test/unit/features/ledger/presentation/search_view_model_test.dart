import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/search_transactions_query.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/transaction_filter.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/search_view_model.dart';

void main() {
  late _SearchQuery query;
  late ProviderContainer container;

  setUp(() async {
    query = _SearchQuery();
    container = ProviderContainer(overrides: [
      searchTransactionsQueryProvider.overrideWithValue(query),
      currencyControllerProvider.overrideWith(() => _FixedCurrency('CNY')),
    ]);
    container.listen(searchResultsProvider, (previous, next) {});
    // Production resolves the setting during bootstrap, long before the
    // search screen opens. Do the same here so the query subscribes once
    // with a settled currency rather than once with the default.
    await container.read(currencyControllerProvider.future);
  });

  tearDown(() => container.dispose());

  test('empty and whitespace queries never subscribe to the ledger', () async {
    expect(
        (await container.read(searchResultsProvider.future)).isEmpty, isTrue);
    container.read(searchViewModelProvider.notifier).setQuery('   ');
    expect(
        (await container.read(searchResultsProvider.future)).isEmpty, isTrue);
    expect(query.filters, isEmpty);
  });

  test('a query maps matching transactions for display', () async {
    container.read(searchViewModelProvider.notifier).apply(
          const TransactionFilter(query: 'rent', accountId: 'cash'),
        );
    final results = await container.read(searchResultsProvider.future);

    expect(query.filters.single,
        const TransactionFilter(query: 'rent', accountId: 'cash'));
    expect(results.tiles.single.id, query.transaction.id);
    expect(results.tiles.single.displayAmount, '12.34');
    expect(results.tiles.single.displaySign, '-');
  });

  test('clearing a search drops previous rows even with active filters',
      () async {
    container.read(searchViewModelProvider.notifier).apply(
          const TransactionFilter(query: 'rent', accountId: 'cash'),
        );
    expect((await container.read(searchResultsProvider.future)).tiles,
        hasLength(1));

    container.read(searchViewModelProvider.notifier).setQuery('');
    final cleared = await container.read(searchResultsProvider.future);
    expect(cleared.tiles, isEmpty);
    expect(query.filters, hasLength(1));
  });

  test('search is scoped to the current currency', () async {
    container.read(searchViewModelProvider.notifier).setQuery('rent');
    await container.read(searchResultsProvider.future);

    expect(query.currencies.single, 'CNY',
        reason: 'the setting\'s currency reaches the query, not the default');
  });
}

class _SearchQuery implements SearchTransactionsQuery {
  final filters = <TransactionFilter>[];
  final currencies = <String?>[];
  final transaction = TransactionEntity(
    id: 'rent',
    amount: -1234,
    type: TransactionKind.expense,
    date: DateTime(2026, 1, 5, 9, 30),
    note: 'rent',
    account: const AccountEntity(
      id: 'cash',
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: 'USD',
      balanceMinor: 0,
      archived: false,
      lastUpdatedEventId: 0,
    ),
    eventId: 1,
  );

  @override
  Stream<List<TransactionEntity>> execute(TransactionFilter filter,
      {String? currencyCode}) {
    filters.add(filter);
    currencies.add(currencyCode);
    return Stream.value([transaction]);
  }
}

class _FixedCurrency extends CurrencyController {
  _FixedCurrency(this.code);

  final String code;

  @override
  Future<String> build() async => code;
}
