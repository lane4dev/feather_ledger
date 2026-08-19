import 'package:feather_ledger/app/design_system/app_button.dart';
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
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/recurring_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_tile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Upcoming recurring bills in the ledger list (spec 004, US2 / C4).
///
/// The row must read as "not yet" without being confused for a real
/// transaction, and the actions it offers must be the honest ones — there is
/// no event stream behind a pending bill, so editing it is not among them.
void main() {
  const cash = AccountEntity(
    id: 'acc_cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'USD',
    balanceMinor: 0,
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

  TransactionTileUiModel tile({required bool isPending}) =>
      TransactionTileUiModel(
        id: isPending ? 'sched_1' : 'tx_1',
        amount: 500000,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 1, 14, 35),
        note: 'Rent',
        category: rent,
        account: cash,
        displayAmount: '5000.00',
        displaySign: '-',
        isPending: isPending,
        seriesId: isPending ? 'series_1' : null,
      );

  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: child),
      );

  group('the pending row', () {
    testWidgets('is muted and tagged, and posted rows are not', (tester) async {
      await tester.pumpWidget(
          wrap(TransactionTile(transaction: tile(isPending: true))));

      // Muted as a whole.
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, lessThan(1.0));
      // Announces itself twice: a clock on the title and a tag on the row.
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      await tester.pumpWidget(
          wrap(TransactionTile(transaction: tile(isPending: false))));

      expect(find.byType(Opacity), findsNothing,
          reason: 'a posted row pays for no extra layer');
      expect(find.byIcon(LucideIcons.clock), findsNothing);
      expect(find.text('Pending'), findsNothing);
    });

    testWidgets('keeps its category tag alongside the pending tag',
        (tester) async {
      await tester.pumpWidget(
          wrap(TransactionTile(transaction: tile(isPending: true))));

      expect(find.text('Rent'), findsWidgets);
      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('the pending bill sheet', () {
    late _RecordingRecurringViewModel viewModel;

    setUp(() => viewModel = _RecordingRecurringViewModel());

    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recurringViewModelProvider.overrideWith(() => viewModel)],
          child: wrap(PendingBillSheet(transaction: tile(isPending: true))),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the scheduled time in the bill details', (tester) async {
      await pumpSheet(tester);
      expect(find.textContaining('14:35'), findsOneWidget);
    });

    /// Delete lives in the top-right overflow menu, so reaching the scope
    /// dialog is two taps: the menu, then the item.
    Future<void> openDeleteDialog(WidgetTester tester) async {
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
    }

    testWidgets('records a bill only after confirming', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      expect(find.text('Record this bill'), findsOneWidget,
          reason: 'recording moves money, so it asks first');
      expect(viewModel.posted, isEmpty);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppButton, 'Post')));
      await tester.pumpAndSettle();

      expect(viewModel.posted, ['sched_1']);
    });

    testWidgets('cancelling the confirmation records nothing', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(viewModel.posted, isEmpty);
    });

    testWidgets('deleting offers all three scopes, narrowest first',
        (tester) async {
      await pumpSheet(tester);

      await openDeleteDialog(tester);

      // The title carries the verb; the options only name the reach, because
      // the same three labels serve editing.
      expect(find.text('Delete recurring bill'), findsOneWidget);
      expect(find.text('This bill'), findsOneWidget);
      expect(find.text('This and following bills'), findsOneWidget);
      expect(find.text('All bills'), findsOneWidget);
      expect(find.text('Bills already recorded are kept'), findsOneWidget,
          reason: 'the widest scope is the one that needs reassuring');
      expect(viewModel.deleted, isEmpty,
          reason: 'nothing happens until the dialog is confirmed');
    });

    testWidgets('deleting applies the chosen scope', (tester) async {
      await pumpSheet(tester);

      await openDeleteDialog(tester);
      await tester.tap(find.text('This and following bills'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, [('sched_1', RecurringScope.thisAndFollowing)]);
    });

    testWidgets('the narrowest scope is the one preselected', (tester) async {
      await pumpSheet(tester);

      await openDeleteDialog(tester);
      // Confirm without touching the radios: it must not take more than the
      // bill that was opened.
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, [('sched_1', RecurringScope.thisOnly)]);
    });

    testWidgets('cancelling the dialog deletes nothing', (tester) async {
      await pumpSheet(tester);

      await openDeleteDialog(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('reports a rejection with its localized message',
        (tester) async {
      viewModel.failure = LedgerErrorCode.scheduledAlreadyPosted;
      await pumpSheet(tester);

      await openDeleteDialog(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('This scheduled transaction was already posted'),
          findsOneWidget);
    });
  });
}

class _RecordingRecurringViewModel extends RecurringViewModel {
  final List<String> posted = [];
  final List<(String, RecurringScope)> deleted = [];
  LedgerErrorCode? failure;

  @override
  void build() {}

  @override
  Future<Result<void>> postInstance(String scheduledId) async {
    if (failure != null) return Failure(failure!, 'rejected');
    posted.add(scheduledId);
    return unitResult;
  }

  @override
  Future<Result<void>> deleteBill(
    String scheduledId, {
    required RecurringScope scope,
  }) async {
    if (failure != null) return Failure(failure!, 'rejected');
    deleted.add((scheduledId, scope));
    return unitResult;
  }
}
