import 'dart:async';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/data/database/app_database.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/features/settings/presentation/widgets/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/event_sourcing/ledger_service_harness.dart';

void main() {
  late LedgerServiceHarness harness;
  setUp(() async {
    harness = LedgerServiceHarness();
    await harness.categoryService.createCategory(
        commandId: 'create',
        categoryId: 'food',
        name: 'Food',
        iconKey: '${CategoryTokens.defaultIcons.first}',
        colorInt: CategoryTokens.defaultColor.toARGB32(),
        type: CategoryType.expense);
  });
  tearDown(() => harness.close());

  testWidgets('editing shows upload and saves a changed icon', (tester) async {
    final category = CategoryEntity(
        id: 'food',
        name: 'Food',
        iconKey: '${CategoryTokens.defaultIcons.first}',
        colorInt: CategoryTokens.defaultColor.toARGB32(),
        type: CategoryType.expense);
    final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(harness.db)]);
    addTearDown(container.dispose);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold()),
      GoRoute(
          path: '/edit',
          builder: (_, __) => Scaffold(
              body: CategoryFormSheet(
                  category: category, type: CategoryType.expense))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    unawaited(router.push('/edit'));
    await tester.pumpAndSettle();
    expect(find.text('Upload icon'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save');
    bool saveEnabled() => tester.widget<FilledButton>(save).onPressed != null;
    expect(saveEnabled(), isFalse);
    await tester.enterText(find.byType(TextFormField), 'Meals');
    await tester.pump();
    expect(saveEnabled(), isTrue);
    await tester.enterText(find.byType(TextFormField), 'Food');
    await tester.pump();
    expect(saveEnabled(), isFalse);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final nextIcon = CategoryTokens.defaultIcons[1];
    await tester.tap(find.byIcon(CategoryTokens.iconFor('$nextIcon')));
    await tester.pump();
    expect(saveEnabled(), isTrue);
    await tester.tap(find.byIcon(CategoryTokens.iconFor('${CategoryTokens.defaultIcons.first}')).last);
    await tester.pump();
    expect(saveEnabled(), isFalse);
    await tester.ensureVisible(find.byIcon(CategoryTokens.iconFor('$nextIcon')));
    await tester.tap(find.byIcon(CategoryTokens.iconFor('$nextIcon')));
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final updated = (await harness.db.categoriesDao.getCategoryById('food'))!;
    expect(updated.iconKey, '$nextIcon');
    expect(updated.name, 'Food');
  });
}
