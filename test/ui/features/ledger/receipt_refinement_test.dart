import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/entities/category.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/queries/get_transaction_history_query.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/pending_bill_sheet.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/transaction_detail_sheet.dart';

void main() {
  const category = CategoryEntity(
    id: 'food',
    name: 'Dining',
    iconKey: '1',
    colorInt: 0xFF5C7A93,
    type: CategoryType.expense,
  );
  const account = AccountEntity(
    id: 'cash',
    name: 'Cash',
    type: AccountType.cash,
    currencyCode: 'CNY',
    balanceMinor: 0,
    archived: false,
    lastUpdatedEventId: 0,
  );

  TransactionTileUiModel tile({
    bool pending = false,
    TransactionKind type = TransactionKind.expense,
    int amount = 123456,
    String displayAmount = '1234.56',
    String displaySign = '-',
    String? note = 'Lunch with the team',
  }) =>
      TransactionTileUiModel(
        id: pending ? 'bill' : 'tx',
        amount: amount,
        type: type,
        date: DateTime(2026, 11, 25, 18, 30),
        note: note,
        category: type.isBalancePurpose ? null : category,
        account: account,
        displayAmount: displayAmount,
        displaySign: displaySign,
        isPending: pending,
        scheduledStatus: pending ? ScheduledTransactionStatus.scheduled : null,
      );

  Future<void> openReceipt(
    WidgetTester tester, {
    required TransactionTileUiModel model,
    bool pending = false,
    bool dark = false,
    double textScale = 1,
    double bottomInset = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.padding =
        FakeViewPadding(bottom: bottomInset * tester.view.devicePixelRatio);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        displayCurrencySymbolProvider.overrideWithValue('¥'),
        getTransactionHistoryProvider.overrideWith(
          (ref, id) async => const <TransactionHistoryEntry>[],
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppReceiptSheet<void>(
                context: context,
                builder: (context) => pending
                    ? PendingBillSheet(transaction: model, currencySymbol: '¥')
                    : TransactionDetailSheet(
                        transaction: model,
                        currencySymbol: '¥',
                      ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Finder sheetSurface() => find
      .descendant(
        of: find.byType(AppReceiptSheet),
        matching: find.byType(PhysicalShape),
      )
      .first;

  testWidgets('the paper floats above the system inset and stays compact',
      (tester) async {
    await openReceipt(tester, model: tile(), bottomInset: 24);

    final rect = tester.getRect(sheetSurface());
    expect(rect.left, closeTo(16, 0.5));
    expect(rect.right, closeTo(384, 0.5));
    expect(rect.bottom, closeTo(900 - 24 - 16, 0.5));
    expect(rect.height, lessThanOrEqualTo(900 * 0.6 + 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail rows are compact and separated only at the sections',
      (tester) async {
    await openReceipt(tester, model: tile());

    expect(find.byType(AppReceiptDivider), findsNWidgets(2));
    final row = find.ancestor(
      of: find.text('Date'),
      matching: find.byType(AppReceiptRow),
    );
    final rowRect = tester.getRect(row);
    expect(rowRect.height, inInclusiveRange(34, 40));

    final sheet = tester.getRect(sheetSurface());
    expect(
        tester.getTopLeft(find.text('Date')).dx, closeTo(sheet.left + 24, 1));
    final date = find.textContaining('November 25, 2026');
    expect(tester.getTopRight(date).dx, closeTo(sheet.right - 24, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending badge sits outside the centred grouped amount',
      (tester) async {
    await openReceipt(tester, model: tile(pending: true), pending: true);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AppReceiptSheet)),
    )!;

    final amount = find.text('-¥1,234.56');
    final badge = find.text(l10n.pendingBill).hitTestable();
    expect(amount, findsOneWidget);
    expect(badge, findsOneWidget);

    final amountRect = tester.getRect(amount);
    final badgeRect = tester.getRect(badge);
    final sheet = tester.getRect(sheetSurface());
    expect(badgeRect.left, greaterThanOrEqualTo(amountRect.right));
    expect(badgeRect.top, lessThan(amountRect.top + 12));
    expect(amountRect.center.dx, closeTo(sheet.center.dx, 0.5));

    final badgeText = tester.widget<Text>(badge);
    expect(badgeText.style?.fontSize, 10.5);
    expect(badgeText.style?.fontWeight, FontWeight.w600);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending receipt keeps the amount centred in dark and large type',
      (tester) async {
    await openReceipt(
      tester,
      model: tile(pending: true),
      pending: true,
      dark: true,
      textScale: 1.6,
    );

    final amount = find.text('-¥1,234.56');
    final sheet = tester.getRect(sheetSurface());
    expect(amount, findsOneWidget);
    expect(tester.getCenter(amount).dx, closeTo(sheet.center.dx, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the barcode steps back and the receipt number is small',
      (tester) async {
    await openReceipt(tester, model: tile());

    final barcode = find.byKey(const ValueKey('transaction-barcode'));
    expect(tester.getSize(barcode).height, 38);
    final painted = tester.widget<CustomPaint>(
      find.descendant(of: barcode, matching: find.byType(CustomPaint)),
    );
    final ink = (painted.painter! as dynamic).color as Color;
    expect(ink.a, closeTo(0.24, 0.01));

    final number = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.style?.fontSize == 10.5 &&
          RegExp(r'^\d( \d)*$').hasMatch(widget.data ?? ''),
    );
    expect(number, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('balance adjustments get one neutral icon and no type row',
      (tester) async {
    await openReceipt(
      tester,
      model: tile(
        type: TransactionKind.balanceAdjustment,
        amount: 1000,
        displayAmount: '10.00',
        note: null,
      ),
    );

    expect(find.byIcon(LucideIcons.slidersHorizontal), findsOneWidget);
    expect(find.text('Balance adjustment'), findsOneWidget);
    expect(find.text('Type'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
