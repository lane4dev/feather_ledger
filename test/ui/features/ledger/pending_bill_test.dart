import 'package:feather_ledger/app/design_system/app_badge.dart';
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
import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
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

  TransactionTileUiModel tile({
    required bool isPending,
    String? note = 'Rent',
    TransactionKind type = TransactionKind.expense,
    CategoryEntity? category = rent,
    AccountEntity? toAccount,
    RecurringSeriesMode mode = RecurringSeriesMode.repeating,
    ScheduledTransactionStatus? scheduledStatus,
  }) =>
      TransactionTileUiModel(
        id: isPending ? 'sched_1' : 'tx_1',
        amount: 500000,
        type: type,
        date: DateTime(2026, 11, 1, 14, 35),
        note: note,
        category: category,
        account: cash,
        toAccount: toAccount,
        displayAmount: '5000.00',
        displaySign: switch (type) {
          TransactionKind.income => '+',
          TransactionKind.expense => '-',
          TransactionKind.transfer ||
          TransactionKind.openingBalance ||
          TransactionKind.balanceAdjustment =>
            '',
        },
        isPending: isPending,
        scheduledStatus: isPending
            ? (scheduledStatus ?? ScheduledTransactionStatus.scheduled)
            : null,
        seriesId: isPending ? 'series_1' : null,
        series: isPending
            ? RecurringTransactionSeriesEntity(
                id: 'series_1',
                description: 'Rent',
                amountMinor: 500000,
                type: RecurringSeriesKind.expense,
                categoryId: rent.id,
                accountId: cash.id,
                frequency: 'MONTHLY',
                startDate: DateTime(2026, 11, 1, 14, 35),
                autoPost: false,
                mode: mode,
              )
            : null,
      );

  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
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
    testWidgets('uses AppBadge.outlined without Opacity muting, and posted rows omit badge',
        (tester) async {
      await tester.pumpWidget(
          wrap(TransactionTile(transaction: tile(isPending: true))));

      expect(find.byType(Opacity), findsNothing,
          reason: 'pending rows keep readable title contrast without Opacity');
      expect(find.byIcon(LucideIcons.clock), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byType(AppBadge), findsOneWidget);

      final titleText = tester.widget<Text>(find.text('Rent'));
      expect(titleText.style?.color, AppTheme.lightTheme.colorScheme.onSurface);

      await tester.pumpWidget(
          wrap(TransactionTile(transaction: tile(isPending: false))));

      expect(find.byType(Opacity), findsNothing);
      expect(find.byIcon(LucideIcons.clock), findsNothing);
      expect(find.text('Pending'), findsNothing);
      expect(find.byType(AppBadge), findsNothing);
    });

    testWidgets('uses two-line structure without inline category pill',
        (tester) async {
      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(isPending: true, note: 'Monthly rent'),
      )));

      expect(find.text('Monthly rent'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Rent'), findsNothing,
          reason: 'inline duplicate category pill was removed');
      expect(find.byType(AppBadge), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Without a note, line 1 falls back to the category snapshot name and
      // line 2 shows the account name.
      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(isPending: false, note: null),
      )));

      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.byType(AppBadge), findsNothing);
      expect(tester.getSize(find.byType(TransactionTile)).height,
          inInclusiveRange(60.0, 68.0));
    });

    testWidgets('renders transfer and balance-purpose tiles with dedicated icons',
        (tester) async {
      const bank = AccountEntity(
        id: 'acc_bank',
        name: 'Bank',
        type: AccountType.bank,
        currencyCode: 'USD',
        balanceMinor: 0,
        archived: false,
        lastUpdatedEventId: 0,
      );

      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(
          isPending: false,
          note: null,
          type: TransactionKind.transfer,
          category: null,
          toAccount: bank,
        ),
      )));
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Cash → Bank'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeftRight), findsOneWidget);

      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(
          isPending: false,
          note: null,
          type: TransactionKind.openingBalance,
          category: null,
        ),
      )));
      expect(find.text('Initial Balance'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.byIcon(LucideIcons.wallet), findsOneWidget);

      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(
          isPending: false,
          note: null,
          type: TransactionKind.balanceAdjustment,
          category: null,
        ),
      )));
      expect(find.text('Balance adjustment'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
    });

    testWidgets('skipped row renders muted onSurfaceVariant with strikethrough and compact Skipped badge',
        (tester) async {
      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(
          isPending: true,
          scheduledStatus: ScheduledTransactionStatus.skipped,
        ),
      )));

      expect(find.byType(Opacity), findsNothing);
      expect(find.text('Skipped'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
      expect(find.byIcon(LucideIcons.circlePause), findsOneWidget);

      final expectedMuted = AppTheme.lightTheme.colorScheme.onSurfaceVariant
          .withValues(alpha: LedgerTheme.skippedTextAlpha);

      final titleText = tester.widget<Text>(find.text('Rent'));
      expect(titleText.style?.decoration, TextDecoration.lineThrough);
      expect(titleText.style?.color, expectedMuted);

      final subtitleText = tester.widget<Text>(find.text('Cash'));
      expect(subtitleText.style?.color, expectedMuted);

      final amountText = tester.widget<Text>(find.text(r'-$5000.00'));
      expect(amountText.style?.decoration, TextDecoration.lineThrough);
      expect(amountText.style?.color, expectedMuted);

      // Badge sits on the same 2nd line immediately after the account name.
      final cashRect = tester.getRect(find.text('Cash'));
      final badgeRect = tester.getRect(find.byType(AppBadge));
      expect(badgeRect.left - cashRect.right, closeTo(6.0, 0.5));
      expect(badgeRect.height, closeTo(20.0, 1.0));
      expect((badgeRect.center.dy - cashRect.center.dy).abs(), lessThan(4.0));

      // Leading circular icon and trailing amount remain vertically centered.
      final tileRect = tester.getRect(find.byType(TransactionTile));
      final amountRect = tester.getRect(find.text(r'-$5000.00'));
      expect((amountRect.center.dy - tileRect.center.dy).abs(), lessThan(2.0));
    });

    testWidgets('failed row renders AppBadge.error without Opacity',
        (tester) async {
      await tester.pumpWidget(wrap(TransactionTile(
        transaction: tile(
          isPending: true,
          scheduledStatus: ScheduledTransactionStatus.failed,
        ),
      )));

      expect(find.byType(Opacity), findsNothing);
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
      expect(find.text('Auto-post failed'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);

      final titleText = tester.widget<Text>(find.text('Rent'));
      expect(titleText.style?.color, AppTheme.lightTheme.colorScheme.onSurface);
    });

    testWidgets('adjusts dark-category foreground contrast in dark theme',
        (tester) async {
      await tester.pumpWidget(wrap(
        TransactionTile(transaction: tile(isPending: false)),
        theme: AppTheme.darkTheme,
      ));

      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, isNot(const Color(0xFF000000)));
      expect(icon.color!.computeLuminance(), greaterThan(0.2));
    });
  });

  group('the pending bill sheet', () {
    late _RecordingRecurringViewModel viewModel;

    setUp(() => viewModel = _RecordingRecurringViewModel());

    Future<void> pumpSheet(
      WidgetTester tester, {
      RecurringSeriesMode mode = RecurringSeriesMode.repeating,
      ScheduledTransactionStatus scheduledStatus =
          ScheduledTransactionStatus.scheduled,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [recurringViewModelProvider.overrideWith(() => viewModel)],
          child: wrap(
            PendingBillSheet(
              transaction: tile(
                isPending: true,
                mode: mode,
                scheduledStatus: scheduledStatus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the scheduled time in the bill details', (tester) async {
      await pumpSheet(tester);
      expect(find.textContaining('14:35'), findsOneWidget);
    });

    Future<void> openMenuItem(WidgetTester tester, String itemText) async {
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text(itemText));
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

    testWidgets('repeating overflow offers Skip and Stop without scope dialog',
        (tester) async {
      await pumpSheet(tester, mode: RecurringSeriesMode.repeating);

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();

      expect(find.text('Skip this bill'), findsOneWidget);
      expect(find.text('Stop repeating'), findsOneWidget);
      expect(find.text('Delete plan'), findsNothing);
    });

    testWidgets('skipping a repeating bill confirms then calls thisOnly',
        (tester) async {
      await pumpSheet(tester, mode: RecurringSeriesMode.repeating);

      await openMenuItem(tester, 'Skip this bill');
      expect(find.text('Skip this bill?'), findsOneWidget);
      expect(viewModel.deleted, isEmpty);

      await tester.tap(find.widgetWithText(AppButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, [('sched_1', RecurringScope.thisOnly)]);
    });

    testWidgets('stopping a repeating rule confirms then calls updateRule',
        (tester) async {
      await pumpSheet(tester, mode: RecurringSeriesMode.repeating);

      await openMenuItem(tester, 'Stop repeating');
      expect(find.text('Stop repeating rule?'), findsOneWidget);
      expect(viewModel.deleted, isEmpty);

      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppButton, 'Stop repeating')));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, [('sched_1', RecurringScope.updateRule)]);
    });

    testWidgets('planned bill overflow only offers Delete plan',
        (tester) async {
      await pumpSheet(tester, mode: RecurringSeriesMode.planned);

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();

      expect(find.text('Delete plan'), findsOneWidget);
      expect(find.text('Skip this bill'), findsNothing);
      expect(find.text('Stop repeating'), findsNothing);

      await tester.tap(find.text('Delete plan'));
      await tester.pumpAndSettle();
      expect(find.text('Delete plan?'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, [('sched_1', RecurringScope.updateRule)]);
    });

    testWidgets('cancelling the dialog deletes nothing', (tester) async {
      await pumpSheet(tester);

      await openMenuItem(tester, 'Skip this bill');
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(viewModel.deleted, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('reports a rejection with its localized message',
        (tester) async {
      viewModel.failure = LedgerErrorCode.scheduledAlreadyPosted;
      await pumpSheet(tester);

      await openMenuItem(tester, 'Skip this bill');
      await tester.tap(find.widgetWithText(AppButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(find.text('This scheduled transaction was already posted'),
          findsOneWidget);
    });

    testWidgets('skipped sheet shows Restore to pending without edit/overflow',
        (tester) async {
      await pumpSheet(
        tester,
        scheduledStatus: ScheduledTransactionStatus.skipped,
      );

      expect(find.text('Skipped'), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
      expect(find.text('Post'), findsNothing);

      await tester.tap(find.text('Restore to pending'));
      await tester.pumpAndSettle();

      expect(viewModel.restored, ['sched_1']);
    });

    testWidgets('failed sheet shows warning banner and Retry post action',
        (tester) async {
      await pumpSheet(
        tester,
        scheduledStatus: ScheduledTransactionStatus.failed,
      );

      expect(find.text('Auto-post failed'), findsOneWidget);
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);

      await tester.tap(find.text('Retry post'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(AppButton, 'Post')));
      await tester.pumpAndSettle();

      expect(viewModel.posted, ['sched_1']);
    });
  });
}

class _RecordingRecurringViewModel extends RecurringViewModel {
  final List<String> posted = [];
  final List<String> restored = [];
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
  Future<Result<void>> restoreSkippedBill(String scheduledId) async {
    if (failure != null) return Failure(failure!, 'rejected');
    restored.add(scheduledId);
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
