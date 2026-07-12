import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';

/// The ledger's app bar (spec 004).
///
/// Three things it has to get right, each of which was wrong before: the month
/// shares a line with the search action rather than floating below it; the
/// bar is not empty once it collapses; and the collapsed bar is empty exactly
/// never — the boundary between the two states is a single scroll offset.
void main() {
  const summary = MonthlySummaryUiModel(
    displayBalance: r'$1,234.56',
    displayIncome: r'$500.00',
    displayExpense: r'$200.00',
  );

  Widget wrap(Widget child, {bool showBalance = true}) => ProviderScope(
        overrides: [
          balanceVisibilityControllerProvider
              .overrideWith(() => _FixedVisibility(showBalance)),
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
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: child,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  group('the collapse boundary', () {
    // The outer scrollable's offset stops at exactly this value, so `>` left
    // the collapsed bar permanently empty.
    test('is crossed when the header is exactly fully collapsed', () {
      expect(isHeaderCollapsed(124, 180), isTrue);
      expect(isHeaderCollapsed(123.9, 180), isFalse);
      expect(isHeaderCollapsed(0, 180), isFalse);
    });
  });

  group('the month', () {
    testWidgets('shares a centre line with the search action', (tester) async {
      await tester.pumpWidget(wrap(LedgerAppBarTitle(
        selectedDate: DateTime(2026, 11),
        summaryAsync: const AsyncData(summary),
        collapsed: false,
      )));
      await tester.pumpAndSettle();

      final monthCentre = tester.getCenter(find.text('November 2026')).dy;
      final searchCentre = tester.getCenter(find.byIcon(Icons.search)).dy;

      expect((monthCentre - searchCentre).abs(), lessThan(1.0),
          reason: 'they are one row of controls, so they line up');
    });

    testWidgets('keeps its steppers while expanded', (tester) async {
      await tester.pumpWidget(wrap(LedgerAppBarTitle(
        selectedDate: DateTime(2026, 11),
        summaryAsync: const AsyncData(summary),
        collapsed: false,
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('once collapsed', () {
    Future<void> pump(WidgetTester tester, {bool showBalance = true}) async {
      await tester.pumpWidget(wrap(
        LedgerAppBarTitle(
          selectedDate: DateTime(2026, 11),
          summaryAsync: const AsyncData(summary),
          collapsed: true,
        ),
        showBalance: showBalance,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('the bar carries the month and the balance', (tester) async {
      await pump(tester);

      expect(find.text('Nov 2026'), findsOneWidget);
      expect(find.text(r'$1,234.56'), findsOneWidget);
    });

    testWidgets('a hidden balance is masked, not dropped', (tester) async {
      await pump(tester, showBalance: false);

      expect(find.text('Nov 2026'), findsOneWidget,
          reason: 'the month is not a balance and is never hidden');
      expect(find.text('******'), findsOneWidget);
      expect(find.text(r'$1,234.56'), findsNothing);
    });

    testWidgets('the steppers give their room to the balance',
        (tester) async {
      await pump(tester);

      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}

class _FixedVisibility extends BalanceVisibilityController {
  _FixedVisibility(this.visible);

  final bool visible;

  @override
  Future<bool> build() async => visible;
}
