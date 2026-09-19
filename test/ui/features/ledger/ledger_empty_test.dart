import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_empty.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onCreateAccount}) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en')],
      home: Scaffold(
        body: LedgerEmpty(onCreateAccount: onCreateAccount),
      ),
    ));
    // The placeholder image loads asynchronously; the text beside it renders
    // synchronously, so one frame is enough for the assertions below.
    await tester.pump();
  }

  testWidgets('accounts exist: shows the no-transactions state', (tester) async {
    await pump(tester);
    expect(find.text('No transactions'), findsOneWidget);
    expect(find.text('Tap + to add a new one'), findsOneWidget);
    expect(find.text('Add Account'), findsNothing);
  });

  testWidgets('no accounts: shows a create-account prompt', (tester) async {
    await pump(tester, onCreateAccount: () {});
    expect(find.text('No accounts in this currency'), findsOneWidget);
    expect(find.text('Create an account to start tracking'), findsOneWidget);
    expect(find.text('Add Account'), findsOneWidget);
    expect(find.text('No transactions'), findsNothing);
  });
}
