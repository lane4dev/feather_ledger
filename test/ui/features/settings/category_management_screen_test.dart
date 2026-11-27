import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/settings/presentation/screens/category_management_screen.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/category_form_sheet.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

void main() {
  late LedgerServiceHarness harness;

  setUp(() async {
    harness = LedgerServiceHarness();
  });

  tearDown(() => harness.close());

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    ThemeData? theme,
    Size size = const Size(400, 700),
    double textScale = 1,
    CategoryType? failingType,
  }) async {
    final overrides = [
      appDatabaseProvider.overrideWithValue(harness.db),
      if (failingType != null)
        categoryListProvider(failingType).overrideWith(
          (ref) => Stream<List<CategoryEntity>>.error(
            StateError('raw database failure'),
          ),
        ),
    ];
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const CategoryManagementScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('switches type with the segmented control and keeps FAB in sync',
      (tester) async {
    await harness.seedCategory(id: 'food', name: 'Food');
    await harness.seedCategory(
        id: 'salary', name: 'Salary', type: CategoryType.income);

    await pumpScreen(tester);

    expect(find.byType(AppSegmentedControl<CategoryType>), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Food'), findsNothing);

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets('swiping the PageView updates the segmented control',
      (tester) async {
    await harness.seedCategory(id: 'food', name: 'Food');
    await harness.seedCategory(
        id: 'salary', name: 'Salary', type: CategoryType.income);

    await pumpScreen(tester);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
    expect(
      tester
          .widget<AppSegmentedControl<CategoryType>>(
              find.byType(AppSegmentedControl<CategoryType>))
          .selected,
      CategoryType.income,
    );
  });

  testWidgets('groups rows in a card with dividers', (tester) async {
    await harness.seedCategory(id: 'food', name: 'Food');
    await harness.seedCategory(id: 'travel', name: 'Travel');

    await pumpScreen(tester);

    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(FeatherDivider), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
  });

  testWidgets('the list bottom padding keeps the last row above the FAB',
      (tester) async {
    for (var i = 1; i <= 14; i++) {
      await harness.seedCategory(id: 'cat-$i', name: 'Category $i');
    }

    await pumpScreen(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    final lastRow = find.ancestor(
      of: find.text('Category 14'),
      matching: find.byType(ListTile),
    );
    expect(lastRow, findsOneWidget);
    expect(
      tester.getRect(lastRow).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byType(FloatingActionButton)).top,
      ),
    );
  });

  testWidgets('empty state offers a create action for the current type',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('No categories yet'), findsOneWidget);
    expect(find.text('Add a category to organize your transactions.'),
        findsOneWidget);
    expect(find.text('Add category'), findsOneWidget);

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets('tapping a row opens the edit sheet', (tester) async {
    await harness.seedCategory(id: 'food', name: 'Food');

    await pumpScreen(tester);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryFormSheet), findsOneWidget);
  });

  testWidgets('load failures stay friendly instead of showing the exception',
      (tester) async {
    await pumpScreen(tester, failingType: CategoryType.expense);

    expect(find.text("Couldn't load categories. Please try again."),
        findsOneWidget);
    expect(find.textContaining('raw database failure'), findsNothing);
  });

  testWidgets('dark theme at 320dp and 1.5x text does not overflow',
      (tester) async {
    await harness.seedCategory(
      id: 'long',
      name: 'A long category name that still needs to fit the row',
    );

    await pumpScreen(
      tester,
      theme: AppTheme.darkTheme,
      size: const Size(320, 700),
      textScale: 1.5,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AppSegmentedControl<CategoryType>), findsOneWidget);
    expect(find.textContaining('A long category'), findsOneWidget);
  });
}
