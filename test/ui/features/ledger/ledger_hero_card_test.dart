import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_expense_trend.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_balance_sparkline.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';

/// The hero card's three states that the layout has to survive: amounts
/// hidden, a month with nothing to plot, and a balance long enough to break a
/// 360dp screen.
void main() {
  const summary = MonthlySummaryUiModel(
    displayBalance: '¥1195.00',
    displayIncome: '¥500.00',
    displayExpense: '¥200.00',
  );

  Widget host({
    required Widget child,
    Size size = const Size(360, 800),
    Brightness brightness = Brightness.light,
    bool showBalance = true,
    double textScale = 1.0,
  }) =>
      ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider
              .overrideWith(() => _FixedVisibility(showBalance)),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      );

  testWidgets('a hidden balance keeps the currency symbol and drops the cents',
      (tester) async {
    await tester.pumpWidget(host(
      showBalance: false,
      child: const LedgerHeader(summaryAsync: AsyncData(summary)),
    ));
    await tester.pumpAndSettle();

    // The mask is one string, so the three-tier span cannot split an asterisk
    // run across two sizes.
    expect(find.text('¥ ****', findRichText: true), findsOneWidget);
    expect(find.text('¥1195.00', findRichText: true), findsNothing);
    expect(find.text('******'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a month with nothing to plot still fills the balance row',
      (tester) async {
    await tester.pumpWidget(host(
      child: const LedgerHeader(
        summaryAsync: AsyncData(summary),
        expenseTrend: LedgerExpenseTrend.empty(),
      ),
    ));
    await tester.pumpAndSettle();

    final sparkline = find.byType(LedgerBalanceSparkline);
    expect(sparkline, findsOneWidget);
    final size = tester.getSize(sparkline);
    expect(size.width, greaterThanOrEqualTo(88));
    expect(size.height, greaterThanOrEqualTo(36));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one day of spending paints without an exception',
      (tester) async {
    await tester.pumpWidget(host(
      child: LedgerHeader(
        summaryAsync: const AsyncData(summary),
        expenseTrend: _singleDayTrend,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(LedgerBalanceSparkline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
        'a long balance does not overflow at 360dp (${brightness.name})',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(
        brightness: brightness,
        size: const Size(360, 800),
        child: const LedgerHeader(
          summaryAsync: AsyncData(MonthlySummaryUiModel(
            displayBalance: '¥128,450.00',
            displayIncome: '¥99,999.00',
            displayExpense: '¥88,888.00',
          )),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('¥128,450.00', findRichText: true), findsOneWidget);
    });
  }

  testWidgets('the card keeps its 24dp plate and hairline in dark mode',
      (tester) async {
    await tester.pumpWidget(host(
      brightness: Brightness.dark,
      child: const LedgerHeader(summaryAsync: AsyncData(summary)),
    ));
    await tester.pumpAndSettle();

    final plate = tester
        .widgetList<DecoratedBox>(find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(24),
          ),
          matching: find.byType(DecoratedBox),
        ))
        .map((d) => d.decoration as BoxDecoration)
        .firstWhere((d) => d.border != null);

    expect(plate.gradient, isA<LinearGradient>());
    expect(plate.border!.top.width, LedgerTheme.overviewBorderWidth);
    expect(
      plate.border!.top.color.a,
      closeTo(LedgerTheme.overviewBorderAlphaDark, 0.001),
    );
  });
}

/// One day, one expense: a point, not a line.
final _singleDayTrend = LedgerExpenseTrend.fromDays([
  LedgerDayGroup(
    date: DateTime(2026, 11, 20),
    transactions: [
      TransactionTileUiModel(
        id: 'tx-1',
        amount: 520,
        type: TransactionKind.expense,
        date: DateTime(2026, 11, 20),
        note: null,
        account: const AccountEntity(
          id: 'acc',
          name: 'Cash',
          type: AccountType.cash,
          currencyCode: 'CNY',
          balanceMinor: 0,
          archived: false,
          lastUpdatedEventId: 1,
        ),
        displayAmount: '5.20',
        displaySign: '-',
      ),
    ],
  ),
]);

class _FixedVisibility extends BalanceVisibilityController {
  _FixedVisibility(this.visible);

  final bool visible;

  @override
  Future<bool> build() async => visible;

  @override
  Future<void> toggle() async => state = AsyncData(!(state.value ?? true));
}
