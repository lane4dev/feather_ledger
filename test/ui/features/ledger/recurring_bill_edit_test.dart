import 'package:feather_ledger/app/design_system/app_bottom_action_bar.dart';
import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/recurring_bill_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selection_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Editing an upcoming recurring bill (spec 004, US2).
///
/// The form opens straight from the pencil and asks how far the change
/// reaches when it is saved. The interesting part is the disagreement that
/// creates: a bill's date and amount live on the instance row, while its
/// category, account and note live on the series — so an edit that touches
/// those cannot be applied to a single bill, and the dialog has to say so
/// rather than accept the edit and drop half of it.
void main() {
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 100000,
    archived: false,
    lastUpdatedEventId: 0,
  );
  const rent = CategoryEntity(
    id: 'cat_rent',
    name: 'Rent',
    iconKey: '1',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );
  const food = CategoryEntity(
    id: 'cat_food',
    name: 'Food',
    iconKey: '2',
    colorInt: 0xFF000000,
    type: CategoryType.expense,
  );

  final tile = TransactionTileUiModel(
    id: 'sched_1',
    amount: 500000,
    type: TransactionKind.expense,
    date: DateTime(2026, 11, 1),
    note: 'Rent',
    category: rent,
    account: cash,
    displayAmount: '5000.00',
    displaySign: '-',
    isPending: true,
    seriesId: 'series_1',
  );

  late _RecordingRecurringViewModel viewModel;

  setUp(() => viewModel = _RecordingRecurringViewModel());

  /// The radio for [scope], found by what it selects rather than by where it
  /// sits — where it sits is one of the things under test.
  Radio<RecurringScope> radioFor(WidgetTester tester, RecurringScope scope) =>
      tester
          .widgetList<Radio<RecurringScope>>(find.byType(Radio<RecurringScope>))
          .firstWhere((radio) => radio.value == scope);

  group('the sheet asks how far the edit reaches', () {
    Object? pushed;

    /// Pumps the sheet behind a router, so the pencil can actually navigate.
    Future<void> pumpSheet(WidgetTester tester) async {
      pushed = null;
      final router = GoRouter(
        initialLocation: '/ledger',
        routes: [
          GoRoute(
            path: '/ledger',
            // The sheet is a modal over the list, as it is in the app —
            // editing pops it, which only means something if there is a page
            // underneath.
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => PendingBillSheet(transaction: tile),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/ledger/edit-bill',
            builder: (context, state) {
              pushed = state.extra;
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringViewModelProvider.overrideWith(() => viewModel),
            accountUiListProvider
                .overrideWithValue(AsyncData([AccountUiModel.of(cash)])),
            categoryListProvider.overrideWith(
              (ref, type) => Stream.value(
                  type == CategoryType.expense ? const [rent, food] : const []),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('offering edit beside delete, and no separate skip',
        (tester) async {
      await pumpSheet(tester);

      expect(find.byIcon(LucideIcons.squarePen), findsOneWidget);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsOneWidget);
      expect(find.text('Skip'), findsNothing,
          reason: 'deleting one bill is what skipping used to be');
    });

    testWidgets('the pencil opens the form directly, with no dialog first',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.byIcon(LucideIcons.squarePen));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing,
          reason: 'how far it reaches is a question about a finished edit');
      expect(viewModel.updated, isEmpty);
      expect((pushed as TransactionTileUiModel).id, 'sched_1');
    });
  });

  group('the form, and the reach asked for at save', () {
    /// The form is a route in the app, and it pops itself on success — so the
    /// test needs a router underneath it, not just a MaterialApp.
    Future<void> pumpForm(WidgetTester tester,
        {String currencyCode = 'USD',
        double bottomInset = 0,
        double textScale = 1}) async {
      final account = AccountEntity(
          id: cash.id,
          name: cash.name,
          type: cash.type,
          currencyCode: currencyCode,
          balanceMinor: cash.balanceMinor,
          archived: false,
          lastUpdatedEventId: 0);
      final formTile = TransactionTileUiModel(
          id: tile.id,
          amount: tile.amount,
          type: tile.type,
          date: tile.date,
          note: tile.note,
          category: tile.category,
          account: account,
          displayAmount: tile.displayAmount,
          displaySign: tile.displaySign,
          isPending: true,
          seriesId: tile.seriesId);

      final router = GoRouter(
        initialLocation: '/ledger/edit-bill',
        routes: [
          GoRoute(
            path: '/ledger',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            routes: [
              GoRoute(
                path: 'edit-bill',
                builder: (_, __) =>
                    RecurringBillFormScreen(transaction: formTile),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringViewModelProvider.overrideWith(() => viewModel),
            accountUiListProvider
                .overrideWithValue(AsyncData([AccountUiModel.of(account)])),
            categoryListProvider.overrideWith(
              (ref, type) => Stream.value(
                  type == CategoryType.expense ? const [rent, food] : const []),
            ),
          ],
          child: MaterialApp.router(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    viewInsets: EdgeInsets.only(bottom: bottomInset),
                    textScaler: TextScaler.linear(textScale)),
                child: child!),
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    Future<void> enterAmount(WidgetTester tester, String amount) async {
      await tester.enterText(
        find.descendant(
          of: find.byType(LedgerAmountInput),
          matching: find.byType(TextFormField),
        ),
        amount,
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'uses the shared title, field columns, account currency and fixed save bar',
        (tester) async {
      await pumpForm(tester, currencyCode: 'CNY', bottomInset: 220);
      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.byType(AppBadge)),
          findsOneWidget);
      expect(tester.getTopLeft(find.byType(AppBadge)).dx,
          greaterThan(tester.getTopRight(find.text('Edit Transaction')).dx));
      expect(find.byTooltip('Cancel'), findsOneWidget);
      expect(
          tester
              .widget<LedgerAmountInput>(find.byType(LedgerAmountInput))
              .currencySymbol,
          '¥');
      expect(find.byType(AppBottomActionBar), findsOneWidget);
      final saveButton = find.widgetWithText(AppButton, 'Save');
      expect(tester.getSize(saveButton).height, 52);
      expect(tester.getSize(saveButton).width, 752);
      expect(tester.getBottomLeft(saveButton).dy, closeTo(600 - 220 - 8, 0.01));
      final date = tester.widget<LedgerSelectorField>(
          find.widgetWithText(LedgerSelectorField, 'Date'));
      expect(date.text, contains(':'),
          reason: 'pending bills show their saved time');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'keeps the title badge on one row on a narrow screen with larger text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await pumpForm(tester, textScale: 1.8);
      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.text('Pending')),
          findsOneWidget);
      expect(tester.getCenter(find.text('Pending')).dy,
          closeTo(tester.getCenter(find.text('Edit Transaction')).dy, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers every field, because the scope is not known yet',
        (tester) async {
      await pumpForm(tester);

      // Nothing is decided about the reach until Save, so nothing may be
      // hidden on the strength of a decision that has not been made.
      expect(find.byType(LedgerSelectorField), findsNWidgets(3),
          reason: 'date, category and account share labelled rows');
      expect(find.text('Rent'), findsWidgets);
      expect(find.text('Cash'), findsWidgets);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('saving asks how far the edit reaches', (tester) async {
      await pumpForm(tester);

      await save(tester);

      expect(find.text('Save recurring bill'), findsOneWidget);
      expect(find.text('This bill'), findsOneWidget);
      expect(find.text('This and following bills'), findsOneWidget);
      expect(find.text('All bills'), findsOneWidget);
      expect(viewModel.updated, isEmpty,
          reason: 'nothing is written until the reach is chosen');
    });

    testWidgets('each radio sits on its own label line', (tester) async {
      await pumpForm(tester);
      await save(tester);

      for (final label in [
        'This bill',
        'This and following bills',
        'All bills'
      ]) {
        final radio = find.byType(Radio<RecurringScope>);
        final index = ['This bill', 'This and following bills', 'All bills']
            .indexOf(label);
        // The radio is not centred against the whole title-plus-hint block:
        // its middle lands on the label's line, not between the two.
        final radioMiddle = tester.getCenter(radio.at(index)).dy;
        final labelTop = tester.getTopLeft(find.text(label)).dy;
        final labelBottom = tester.getBottomLeft(find.text(label)).dy;
        expect(radioMiddle, greaterThanOrEqualTo(labelTop - 1),
            reason: '$label: the radio is above its label');
        expect(radioMiddle, lessThanOrEqualTo(labelBottom + 1),
            reason: '$label: the radio is below its label');
      }
    });

    testWidgets('the options sit 16 apart, not the tile\'s two-line height',
        (tester) async {
      await pumpForm(tester);
      await save(tester);

      final firstBottom = tester.getBottomLeft(find.text('This bill')).dy;
      final secondTop =
          tester.getTopLeft(find.text('This and following bills')).dy;
      final gap = secondTop - firstBottom;

      // A default ListTile reserves two-line height for every option; these
      // are one line each with a hint only on the last.
      // Two sm of row padding, and nothing else: the radio's box is the
      // label's line height, so it adds no slack of its own.
      expect(gap, closeTo(16, 1), reason: 'measured gap between options: $gap');
    });

    testWidgets('the chosen reach and the new amount are what get sent',
        (tester) async {
      await pumpForm(tester);
      await enterAmount(tester, '6000.00');

      await save(tester);
      await tester.tap(find.text('This and following bills'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppButton, 'Save')));
      await tester.pumpAndSettle();

      expect(viewModel.updated, hasLength(1));
      final call = viewModel.updated.single;
      expect(call.$1, 'sched_1');
      expect(call.$2, RecurringScope.thisAndFollowing);
      expect(call.$3, 600000);
    });

    testWidgets('the narrowest reach is preselected', (tester) async {
      await pumpForm(tester);

      await save(tester);
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppButton, 'Save')));
      await tester.pumpAndSettle();

      expect(viewModel.updated.single.$2, RecurringScope.thisOnly,
          reason: 'confirming without choosing must not reach further');
    });

    testWidgets('cancelling the dialog saves nothing', (tester) async {
      await pumpForm(tester);

      await save(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(viewModel.updated, isEmpty);
    });

    testWidgets(
        'changing the category rules out "only this bill" rather than '
        'dropping the change', (tester) async {
      await pumpForm(tester);

      // Change something only the series can hold.
      await tester.tap(find.widgetWithText(LedgerSelectorField, 'Category'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(LedgerSelectionSheet<CategoryEntity>),
          matching: find.text('Food'),
        ),
      );
      await tester.pumpAndSettle();

      await save(tester);

      // The option is still listed — a missing one reads as a bug — but it
      // cannot be chosen, and the dialog says why.
      expect(find.text('This bill'), findsOneWidget);
      expect(radioFor(tester, RecurringScope.thisOnly).enabled, isFalse);
      expect(find.textContaining('belong to the whole rule'), findsOneWidget);
    });

    testWidgets('with only the amount touched, every reach stays available',
        (tester) async {
      await pumpForm(tester);
      await enterAmount(tester, '6000.00');

      await save(tester);

      for (final scope in RecurringScope.values) {
        expect(radioFor(tester, scope).enabled, isTrue,
            reason: '$scope can hold an amount');
      }
    });

    testWidgets('reports a rejection with its localized message',
        (tester) async {
      viewModel.failure = LedgerErrorCode.scheduledDateTaken;
      await pumpForm(tester);

      await save(tester);
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppButton, 'Save')));
      await tester.pumpAndSettle();

      expect(find.text('This series already has a bill on that date'),
          findsOneWidget);
    });
  });
}

class _RecordingRecurringViewModel extends RecurringViewModel {
  final List<(String, RecurringScope, int)> updated = [];
  LedgerErrorCode? failure;

  @override
  void build() {}

  @override
  Future<Result<void>> updateBill(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) async {
    if (failure != null) return Failure(failure!, 'rejected');
    updated.add((scheduledId, scope, amountMinor));
    return unitResult;
  }
}
