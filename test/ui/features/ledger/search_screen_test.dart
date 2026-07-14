import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/transaction_filter.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/search_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/search_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The search screen (spec 004, US3 / T054).
///
/// The filter itself is covered against a real database in
/// `transaction_dao_filter_test.dart` and `ledger_repository_filter_test.dart`.
/// What is left for this layer is the screen's contract: results render on the
/// ledger's own timeline, an empty result says so, and export is only offered
/// when there is something to export.
void main() {
  late _FakeSearchViewModel viewModel;

  setUp(() => viewModel = _FakeSearchViewModel());

  /// The screen renders `days`, which the real provider builds from the same
  /// rows — so a fixture states its rows once and this keeps the two shapes
  /// from drifting.
  SearchResults resultsOf(List<TransactionTileUiModel> tiles) => SearchResults(
        entities: const [],
        tiles: tiles,
        days: LedgerDayGroup.group(tiles, currencySymbol: r'$'),
      );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchViewModelProvider.overrideWith(() => viewModel),
          searchResultsProvider.overrideWith((ref) => viewModel.results),
          currencyControllerProvider.overrideWith(_FixedCurrency.new),
          accountUiListProvider.overrideWithValue(const AsyncData([])),
          categoryListProvider.overrideWith(
              (ref, type) => const Stream.empty()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders matching transactions', (tester) async {
    viewModel.results = Stream.value(
      resultsOf([_tile(amount: -1234)]),
    );
    await pumpScreen(tester);

    // Not `findsOneWidget`: the timeline renders the amount in the day group
    // as well as on the row, and pinning the count would make this fail on a
    // layout change rather than a behaviour change.
    expect(find.textContaining('12.34'), findsWidgets);
    expect(find.text('No matching transactions'), findsNothing);
  });

  testWidgets('an empty result says so', (tester) async {
    viewModel.results = Stream.value(
      resultsOf(const []),
    );
    await pumpScreen(tester);

    expect(find.text('No matching transactions'), findsOneWidget);
  });

  testWidgets('export is disabled while there is nothing to export',
      (tester) async {
    // Exporting an empty file, or one that disagrees with the screen, would
    // be worse than offering no button.
    viewModel.results = Stream.value(
      resultsOf(const []),
    );
    await pumpScreen(tester);

    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, LucideIcons.share2),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('export is enabled and exports exactly what is shown',
      (tester) async {
    viewModel.results = Stream.value(
      resultsOf([_tile(amount: -1234)]),
    );
    await pumpScreen(tester);

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.share2));
    await tester.pumpAndSettle();

    expect(viewModel.exported, hasLength(1),
        reason: 'the rows the screen was showing');
  });

  testWidgets('typing updates the filter', (tester) async {
    viewModel.results =
        Stream.value(resultsOf(const []));
    await pumpScreen(tester);

    await tester.enterText(
      find.byType(TextFormField),
      'rent',
    );
    await tester.pumpAndSettle();

    expect(viewModel.queries, ['rent']);
  });

  testWidgets('exporting a rejected write reports the localized message',
      (tester) async {
    viewModel.results = Stream.value(
      resultsOf([_tile(amount: -1234)]),
    );
    viewModel.exportFailure = LedgerErrorCode.unknownEvent;
    await pumpScreen(tester);

    await tester.tap(find.widgetWithIcon(IconButton, LucideIcons.share2));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'),
        findsOneWidget);
  });
}

TransactionTileUiModel _tile({required int amount}) => TransactionTileUiModel(
      id: 'tx_1',
      amount: amount,
      type: amount < 0 ? TransactionKind.expense : TransactionKind.income,
      date: DateTime(2026, 1, 5),
      note: 'note',
      category: const CategoryEntity(
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
      displaySign: '-',
    );

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}

class _FakeSearchViewModel extends SearchViewModel {
  Stream<SearchResults> results = Stream.value(const SearchResults(
        entities: [],
        tiles: [],
        days: [],
      ));
  LedgerErrorCode? exportFailure;

  final List<String> queries = [];
  final List<List<Object?>> exported = [];

  @override
  TransactionFilter build() => TransactionFilter.empty;

  @override
  void setQuery(String query) {
    queries.add(query);
    super.setQuery(query);
  }

  @override
  Future<Result<void>> export(List<dynamic> rows) async {
    final failure = exportFailure;
    if (failure != null) return Failure(failure, 'rejected');
    exported.add(rows);
    return unitResult;
  }
}
