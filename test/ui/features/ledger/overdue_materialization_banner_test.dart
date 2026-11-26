import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/core/presentation/providers/account_providers.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/models/ledger_day_group.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/ledger_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/view_model/ledger_view_model.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/overdue_materialization_banner.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';

class _VisibleBalance extends BalanceVisibilityController {
  @override
  Future<bool> build() async => true;
}

class _InitialOverdueNotice extends OverdueMaterializationNotice {
  _InitialOverdueNotice(this.initial);
  final OverdueMaterializationNoticeState initial;

  @override
  OverdueMaterializationNoticeState build() => initial;
}

void main() {
  Future<ProviderContainer> pumpLedger(
    WidgetTester tester, {
    OverdueMaterializationNoticeState initialNotice =
        OverdueMaterializationNoticeState.empty,
  }) async {
    const summary = MonthlySummaryUiModel(
      displayBalance: r'$0',
      displayIncome: r'$0',
      displayExpense: r'$0',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        balanceVisibilityControllerProvider.overrideWith(_VisibleBalance.new),
        displayCurrencySymbolProvider.overrideWith((ref) => r'$'),
        accountListProvider
            .overrideWith((ref) => Stream.value(const <AccountEntity>[])),
        pendingBillMonthsProvider
            .overrideWith((ref) => Stream.value(const <DateTime>{})),
        ledgerMonthlySummaryProvider
            .overrideWith((ref, month) => Stream.value(summary)),
        ledgerMonthlyTransactionsProvider
            .overrideWith((ref, month) => Stream.value(const <LedgerDayGroup>[])),
        overdueMaterializationNoticeProvider
            .overrideWith(() => _InitialOverdueNotice(initialNotice)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LedgerScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(LedgerScreen)));
  }

  testWidgets('hides the overdue banner when notice state is empty',
      (tester) async {
    await pumpLedger(tester);

    expect(find.byType(OverdueMaterializationBanner), findsNothing);
    expect(find.textContaining('overdue bill'), findsNothing);
    expect(find.byIcon(LucideIcons.x), findsNothing);
  });

  testWidgets('shows overdue count banner and dismisses it for the session',
      (tester) async {
    final container = await pumpLedger(
      tester,
      initialNotice: const OverdueMaterializationNoticeState(overdueCount: 3),
    );

    expect(find.text('Added 3 overdue bills to review'), findsOneWidget);
    expect(
      container.read(overdueMaterializationNoticeProvider),
      const OverdueMaterializationNoticeState(overdueCount: 3),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(find.text('Added 3 overdue bills to review'), findsNothing);
    expect(
      container.read(overdueMaterializationNoticeProvider),
      OverdueMaterializationNoticeState.empty,
    );
  });

  testWidgets(
      'shows transparent truncation notice alongside overdue count when dormant history was capped',
      (tester) async {
    final container = await pumpLedger(
      tester,
      initialNotice: const OverdueMaterializationNoticeState(
        overdueCount: 100,
        hasTruncatedHistory: true,
      ),
    );

    expect(find.text('Added 100 overdue bills to review'), findsOneWidget);
    expect(
      find.text(
          'Older long-dormant scheduled bills were skipped automatically.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(
      container.read(overdueMaterializationNoticeProvider),
      OverdueMaterializationNoticeState.empty,
    );
    expect(find.textContaining('long-dormant'), findsNothing);
  });

  testWidgets(
      'shows truncation-only banner when only auto-post series had older history skipped',
      (tester) async {
    await pumpLedger(
      tester,
      initialNotice: const OverdueMaterializationNoticeState(
        hasTruncatedHistory: true,
      ),
    );

    expect(
      find.text(
          'Older long-dormant scheduled bills were skipped automatically.'),
      findsOneWidget,
    );
    expect(find.textContaining('Added'), findsNothing);
  });

  testWidgets(
      'shows auto-post circuit breaker notice when overdue auto-post bills were paused for manual review',
      (tester) async {
    final container = await pumpLedger(
      tester,
      initialNotice: const OverdueMaterializationNoticeState(
        circuitBreakerLatchedCount: 15,
      ),
    );

    expect(
      find.text(
          'Paused auto-post for 15 overdue bills — please review manually.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(
      container.read(overdueMaterializationNoticeProvider),
      OverdueMaterializationNoticeState.empty,
    );
    expect(find.textContaining('Paused auto-post'), findsNothing);
  });
}
