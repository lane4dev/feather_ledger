import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pending-bill marker (spec 006, US33): months that still owe a bill get
/// a dot in the month picker, so an overdue bill is findable without paging
/// through every month.
void main() {
  Finder dot() => find.byWidgetPredicate((w) {
        if (w is! Container) return false;
        final decoration = w.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle;
      });

  Future<void> pumpPicker(
    WidgetTester tester, {
    required DateTime initial,
    Set<DateTime> markedMonths = const {},
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => FeatherMonthPicker.show(
              context,
              initialDate: initial,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              markedMonths: markedMonths,
              onMonthSelected: (_) {},
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a marked month shows a dot and nothing else does',
      (tester) async {
    await pumpPicker(
      tester,
      initial: DateTime(2026, 3),
      markedMonths: {DateTime(2026, 3)},
    );

    expect(dot(), findsOneWidget);
  });

  testWidgets('no marked months render no dots', (tester) async {
    await pumpPicker(tester, initial: DateTime(2026, 3));

    expect(dot(), findsNothing);
  });
}
