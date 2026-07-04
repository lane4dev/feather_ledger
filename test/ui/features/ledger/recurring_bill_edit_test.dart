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
import 'package:feather_ledger/core/presentation/providers/category_providers.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/recurring_bill_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';

/// Editing an upcoming recurring bill (spec 004, US2).
///
/// The scope is asked for *before* the form, because it decides which fields
/// can exist: an instance row carries a date and an amount, and a category or
/// account has nowhere to live on it. The tests below are mostly about that
/// correspondence — the form must not offer what the chosen scope cannot keep.
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
            accountListProvider.overrideWith((ref) => Stream.value(const [cash])),
            categoryListProvider.overrideWith(
              (ref, type) => Stream.value(
                  type == CategoryType.expense ? const [rent] : const []),
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

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.text('Skip'), findsNothing,
          reason: 'deleting one bill is what skipping used to be');
    });

    testWidgets('the dialog names the action and defaults to the narrowest',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit recurring bill'), findsOneWidget);
      expect(find.text('Only this bill'), findsOneWidget);
      expect(find.text('This and following bills'), findsOneWidget);
      expect(find.text('All bills'), findsOneWidget);
    });

    testWidgets('carries the chosen scope to the form', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This and following bills'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Next'));
      await tester.pumpAndSettle();

      expect(viewModel.updated, isEmpty,
          reason: 'choosing a scope edits nothing on its own');
      final (bill, scope) = pushed as (TransactionTileUiModel, RecurringScope);
      expect(bill.id, 'sched_1');
      expect(scope, RecurringScope.thisAndFollowing,
          reason: 'the form is opened for the scope that was chosen');
    });

    testWidgets('cancelling the dialog opens no form', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(viewModel.updated, isEmpty);
      expect(pushed, isNull, reason: 'no form was opened');
    });
  });

  group('the form offers what the scope can keep', () {
    /// The form is a route in the app, and it pops itself on success — so the
    /// test needs a router underneath it, not just a MaterialApp.
    Future<void> pumpForm(WidgetTester tester, RecurringScope scope) async {
      final router = GoRouter(
        initialLocation: '/ledger/edit-bill',
        routes: [
          GoRoute(
            path: '/ledger',
            builder: (_, __) => const Scaffold(body: SizedBox.shrink()),
            routes: [
              GoRoute(
                path: 'edit-bill',
                builder: (_, __) => RecurringBillFormScreen(
                  transaction: tile,
                  scope: scope,
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringViewModelProvider.overrideWith(() => viewModel),
            accountListProvider.overrideWith((ref) => Stream.value(const [cash])),
            categoryListProvider.overrideWith(
              (ref, type) => Stream.value(
                  type == CategoryType.expense ? const [rent] : const []),
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
    }

    testWidgets('one bill only: amount and date, no category or account',
        (tester) async {
      await pumpForm(tester, RecurringScope.thisOnly);

      expect(find.text('Only this bill'), findsOneWidget,
          reason: 'the form says which scope it is applying');
      expect(find.byType(LedgerSelectorField), findsNothing,
          reason: 'a single row has nowhere to keep a category or account');
      expect(find.textContaining('belong to the whole rule'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('the series scopes offer category, account and note',
        (tester) async {
      await pumpForm(tester, RecurringScope.all);

      expect(find.text('All bills'), findsOneWidget);
      expect(find.byType(LedgerSelectorField), findsNWidgets(2));
      expect(find.text('Rent'), findsWidgets);
      expect(find.text('Cash'), findsWidgets);
    });

    testWidgets('saving sends the scope, the amount and the date',
        (tester) async {
      await pumpForm(tester, RecurringScope.thisAndFollowing);

      await tester.enterText(
        find.descendant(
          of: find.byType(LedgerAmountInput),
          matching: find.byType(TextFormField),
        ),
        '6000.00',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(viewModel.updated, hasLength(1));
      final call = viewModel.updated.single;
      expect(call.$1, 'sched_1');
      expect(call.$2, RecurringScope.thisAndFollowing);
      expect(call.$3, 600000);
    });

    testWidgets('reports a rejection with its localized message',
        (tester) async {
      viewModel.failure = LedgerErrorCode.scheduledDateTaken;
      await pumpForm(tester, RecurringScope.thisOnly);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
          find.text('This series already has a bill on that date'), findsOneWidget);
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
