import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_transaction_history_query.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/transaction_filter.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/search_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/search_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_timeline.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/search_transaction_tile.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/time_anchor.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_detail_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The search screen (spec 004, US3 / T054).
///
/// The filter itself is covered against a real database in
/// `transaction_dao_filter_test.dart` and `ledger_repository_filter_test.dart`.
/// What is left for this layer is the screen's contract: results render on the
/// ordinary list, an empty query stays blank, and tapping a result opens it.
void main() {
  late _FakeSearchViewModel viewModel;
  late _RecordingLedgerViewModel ledgerViewModel;
  TransactionTileUiModel? edited;

  setUp(() {
    viewModel = _FakeSearchViewModel();
    ledgerViewModel = _RecordingLedgerViewModel();
    edited = null;
  });

  SearchResults resultsOf(List<TransactionTileUiModel> tiles) => SearchResults(
        tiles: tiles,
      );

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? query = 'note',
    bool nestedNavigator = false,
  }) async {
    final routes = [
      GoRoute(path: '/', builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: '/ledger/edit',
        builder: (context, state) {
          edited = state.extra! as TransactionTileUiModel;
          return Scaffold(
            body: Column(children: [
              const Text('Edit transaction'),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Return to search'),
              ),
            ]),
          );
        },
      ),
    ];
    final router = GoRouter(
        routes: nestedNavigator
            ? [
                ShellRoute(
                    builder: (context, state, child) => child, routes: routes)
              ]
            : routes);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWith(() => viewModel),
          ledgerViewModelProvider.overrideWith(() => ledgerViewModel),
          searchResultsProvider.overrideWith((ref) => viewModel.results),
          getTransactionHistoryProvider
              .overrideWith((ref, id) async => const []),
          currencyControllerProvider.overrideWith(_FixedCurrency.new),
          // The symbol on a row follows the ledger's currency, which is the
          // accounts' — with none, it falls through to the preference above.
          accountListProvider.overrideWithValue(const AsyncData([])),
          accountUiListProvider.overrideWithValue(const AsyncData([])),
          categoryListProvider
              .overrideWith((ref, type) => const Stream.empty()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (query != null) {
      await tester.enterText(find.byType(TextFormField), query);
      await tester.pumpAndSettle();
    }
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  testWidgets('renders matching transactions', (tester) async {
    viewModel.results = Stream.value(
      resultsOf([_tile(amount: -1234)]),
    );
    await pumpScreen(tester);

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(SearchTransactionTile), findsOneWidget);
    expect(find.byType(LedgerTimeline), findsNothing);
    expect(find.byType(TimeAnchor), findsNothing);
    expect(find.widgetWithIcon(IconButton, LucideIcons.share2), findsNothing);
    expect(find.widgetWithIcon(IconButton, LucideIcons.filter), findsOneWidget);
    expect(find.textContaining('12.34'), findsOneWidget);
    expect(
        find.descendant(
          of: find.byType(SearchTransactionTile),
          matching: find.text('note'),
        ),
        findsOneWidget);
    expect(find.textContaining('Expense · Food · Cash'), findsOneWidget);
    expect(
        find.textContaining(DateFormat.yMd('en').add_Hm().format(
              DateTime(2026, 1, 5, 9, 30),
            )),
        findsOneWidget);
    expect(find.text('No matching transactions'), findsNothing);
  });

  testWidgets('an empty query hides results', (tester) async {
    viewModel.results = Stream.value(resultsOf([_tile(amount: -1234)]));
    await pumpScreen(tester, query: null);

    expect(find.byType(SearchTransactionTile), findsNothing);
    expect(find.text('No matching transactions'), findsNothing);
  });

  testWidgets('clearing the query or entering spaces hides previous results',
      (tester) async {
    viewModel.results = Stream.value(resultsOf([_tile(amount: -1234)]));
    await pumpScreen(tester);
    expect(find.byType(SearchTransactionTile), findsOneWidget);

    for (final query in ['', '   ']) {
      await tester.enterText(find.byType(TextFormField), query);
      await tester.pumpAndSettle();
      expect(find.byType(SearchTransactionTile), findsNothing);
      expect(find.text('No matching transactions'), findsNothing);
    }
  });

  testWidgets(
      'a transfer opens details before editing through a nested navigator',
      (tester) async {
    final transfer = _tile(
      amount: 1234,
      kind: TransactionKind.transfer,
      note: null,
      toAccount: const AccountEntity(
        id: 'bank',
        name: 'Bank',
        type: AccountType.bank,
        currencyCode: 'USD',
        balanceMinor: 0,
        archived: false,
        lastUpdatedEventId: 0,
      ),
    );
    viewModel.results = Stream.value(resultsOf([transfer]));
    await pumpScreen(tester, query: 'Bank', nestedNavigator: true);

    expect(find.text('Transfer'), findsOneWidget);
    expect(find.textContaining('Cash → Bank'), findsOneWidget);
    await tester.tap(find.byType(SearchTransactionTile));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(
        find.descendant(
          of: find.byType(TransactionDetailSheet),
          matching: find.text('Bank'),
        ),
        findsOneWidget);
    expect(edited, isNull);
    await tester.tap(find.byIcon(LucideIcons.squarePen));
    await tester.pumpAndSettle();
    expect(edited, same(transfer));
    expect(find.text('Edit transaction'), findsOneWidget);
    expect(find.byType(TransactionDetailSheet), findsNothing);
    await tester.tap(find.text('Return to search'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Bank');
    expect(find.byType(SearchTransactionTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'closing details and returning from editing preserve search state and scroll',
      (tester) async {
    viewModel.results = Stream.value(resultsOf([
      for (var index = 0; index < 30; index++)
        _tile(amount: -1234, id: 'tx_$index', note: 'note $index'),
    ]));
    await pumpScreen(tester);
    const filter = TransactionFilter(
        query: 'note', kind: TransactionKind.expense, accountId: 'acc');
    viewModel.apply(filter);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    final position = Scrollable.of(tester.element(
      find.byType(SearchTransactionTile).hitTestable().first,
    )).position;
    final offset = position.pixels;
    expect(offset, greaterThan(0));
    final row = find.byType(SearchTransactionTile).hitTestable().at(1);
    final selected = tester.widget<SearchTransactionTile>(row).transaction;

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
    expect(edited, isNull);
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(offset, 0.01));
    expect(viewModel.state, filter);

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.squarePen));
    await tester.pumpAndSettle();
    expect(edited, same(selected));
    await tester.tap(find.text('Return to search'));
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(offset, 0.01));
    expect(viewModel.state, filter);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'note');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling deletion keeps details open without deleting',
      (tester) async {
    viewModel.results = Stream.value(resultsOf([_tile(amount: -1234)]));
    await pumpScreen(tester);
    await tester.tap(find.byType(SearchTransactionTile));
    await tester.pumpAndSettle();
    await openDeleteDialog(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(ledgerViewModel.deletedIds, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(TransactionDetailSheet), findsOneWidget);
  });

  testWidgets('confirmed deletion closes details and updates search results',
      (tester) async {
    final updates = StreamController<SearchResults>();
    addTearDown(updates.close);
    viewModel.results = updates.stream;
    updates.add(resultsOf([_tile(amount: -1234)]));
    ledgerViewModel.onDelete = () => updates.add(resultsOf([]));
    await pumpScreen(tester, nestedNavigator: true);
    await tester.tap(find.byType(SearchTransactionTile));
    await tester.pumpAndSettle();
    await openDeleteDialog(tester);
    expect(ledgerViewModel.deletedIds, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(ledgerViewModel.deletedIds, ['tx_1']);
    expect(find.byType(TransactionDetailSheet), findsNothing);
    expect(find.byType(SearchTransactionTile), findsNothing);
    expect(find.text('No matching transactions'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'note');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed deletion shows its localized error on the search page',
      (tester) async {
    ledgerViewModel.failure = LedgerErrorCode.unknownEvent;
    viewModel.results = Stream.value(resultsOf([_tile(amount: -1234)]));
    await pumpScreen(tester);
    await tester.tap(find.byType(SearchTransactionTile));
    await tester.pumpAndSettle();
    await openDeleteDialog(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
        find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.byType(SearchTransactionTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty result says so', (tester) async {
    viewModel.results = Stream.value(
      resultsOf(const []),
    );
    await pumpScreen(tester);

    expect(find.text('No matching transactions'), findsOneWidget);
  });

  testWidgets('typing updates the filter', (tester) async {
    viewModel.results = Stream.value(resultsOf(const []));
    await pumpScreen(tester, query: null);

    await tester.enterText(
      find.byType(TextFormField),
      'rent',
    );
    await tester.pumpAndSettle();

    expect(viewModel.queries, ['rent']);
  });
}

TransactionTileUiModel _tile({
  required int amount,
  String id = 'tx_1',
  TransactionKind? kind,
  String? note = 'note',
  AccountEntity? toAccount,
}) =>
    TransactionTileUiModel(
      id: id,
      amount: amount.abs(),
      type: kind ??
          (amount < 0 ? TransactionKind.expense : TransactionKind.income),
      date: DateTime(2026, 1, 5, 9, 30),
      note: note,
      toAccount: toAccount,
      category: kind == TransactionKind.transfer
          ? null
          : const CategoryEntity(
              id: 'cat',
              name: 'Food',
              iconKey: '1',
              colorInt: 0xFF000000,
              type: CategoryType.expense,
            ),
      account: const AccountEntity(
        id: 'acc',
        name: 'Cash',
        type: AccountType.cash,
        currencyCode: 'USD',
        balanceMinor: 0,
        archived: false,
        lastUpdatedEventId: 0,
      ),
      displayAmount: '12.34',
      displaySign: kind == TransactionKind.transfer
          ? ''
          : amount < 0
              ? '-'
              : '+',
    );

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}

class _FakeSearchViewModel extends SearchViewModel {
  Stream<SearchResults> results = Stream.value(const SearchResults(
    tiles: [],
  ));

  final List<String> queries = [];

  @override
  TransactionFilter build() => TransactionFilter.empty;

  @override
  void setQuery(String query) {
    queries.add(query);
    super.setQuery(query);
  }
}

class _RecordingLedgerViewModel extends LedgerViewModel {
  final deletedIds = <String>[];
  LedgerErrorCode? failure;
  VoidCallback? onDelete;

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    deletedIds.add(id);
    if (failure case final code?) return Failure(code, 'rejected');
    onDelete?.call();
    return unitResult;
  }
}
