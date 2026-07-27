import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_amount_input.dart';

/// The amount field: controlled from outside, reporting raw text, and the one
/// place where the currency symbol is drawn by hand.
///
/// The conversions to and from minor units are deliberately not this widget's
/// — it must not re-format while the user types, or the caret jumps to the end
/// on every keystroke. These tests pin that.
void main() {
  late TextEditingController controller;
  late List<String> changes;
  final formKey = GlobalKey<FormState>();

  setUp(() {
    controller = TextEditingController();
    changes = [];
  });
  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    TransactionKind type = TransactionKind.expense,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: Form(
              key: formKey,
              child: LedgerAmountInput(
                controller: controller,
                onChanged: changes.add,
                type: type,
                currencySymbol: '¥',
              ),
            ),
          ),
        ),
      );

  /// Every [AnimatedOpacity] between the symbol and the root — the widget the
  /// framework fades a decoration's `prefixText` out with.
  Iterable<double> opacitiesAbove(WidgetTester tester, Finder symbol) =>
      tester
          .widgetList<AnimatedOpacity>(
            find.ancestor(of: symbol, matching: find.byType(AnimatedOpacity)),
          )
          .map((w) => w.opacity);

  testWidgets('the symbol is visible on an untouched field', (tester) async {
    await pump(tester);

    // The state a *new* entry opens in: empty, and not yet focused.
    // `InputDecoration.prefixText` is faded right out here — it is drawn
    // inside an `_AffixText` whose opacity follows "the label should
    // withdraw" — so the amount used to sit there with no unit at all until
    // the user tapped in.
    expect(find.text('¥ '), findsOneWidget);
    expect(opacitiesAbove(tester, find.text('¥ ')), isNot(contains(0.0)));
  });

  testWidgets('the field shows what the controller holds', (tester) async {
    controller.text = '12.00';
    await pump(tester);

    // Seeding is the caller's job, formatting included: the field renders the
    // text it is given rather than re-deriving it from a number.
    expect(find.text('12.00'), findsOneWidget);
    expect(opacitiesAbove(tester, find.text('¥ ')), isNot(contains(0.0)));
  });

  testWidgets('typing is reported raw, never re-formatted', (tester) async {
    await pump(tester);

    // "12." on the way to "12.5". A field that re-formatted as you type would
    // answer "12.00" here and put the caret after it.
    await tester.enterText(find.byType(TextFormField), '12.');
    await tester.pump();

    expect(find.text('12.'), findsOneWidget);
    expect(changes.last, '12.');
  });

  testWidgets('a third decimal is refused', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField), '1.23');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '1.234');
    await tester.pump();

    expect(find.text('1.234'), findsNothing);
    expect(find.text('1.23'), findsOneWidget);
  });

  testWidgets('the amount has to be a positive number', (tester) async {
    await pump(tester);

    Future<String?> validate() async {
      formKey.currentState!.validate();
      await tester.pump();
      if (find.text('Required').evaluate().isNotEmpty) return 'Required';
      if (find.text('Invalid amount').evaluate().isNotEmpty) {
        return 'Invalid amount';
      }
      return null;
    }

    expect(await validate(), 'Required');

    // "." passes the formatter on the way to ".5" — the validator has to
    // survive it rather than throw.
    for (final rejected in ['0', '0.00', '.']) {
      await tester.enterText(find.byType(TextFormField), rejected);
      await tester.pump();
      expect(await validate(), 'Invalid amount', reason: 'for "$rejected"');
    }

    await tester.enterText(find.byType(TextFormField), '0.01');
    await tester.pump();
    expect(await validate(), isNull);
  });

  group('a balance purpose', () {
    // Income, expense and transfer say the direction with their kind, so their
    // amount is a magnitude. An opening balance or an adjustment has no such
    // kind — the sign is the direction — and that sign is typed.
    testWidgets('takes a minus, and a plus clears it again', (tester) async {
      await pump(tester, type: TransactionKind.openingBalance);

      await tester.enterText(find.byType(TextFormField), '-500');
      await tester.pump();
      expect(find.text('-500'), findsOneWidget);
      expect(changes.last, '-500');

      // A physical keyboard's `+` means "positive": it clears the sign rather
      // than becoming part of the number.
      await tester.enterText(find.byType(TextFormField), '+-500');
      await tester.pump();
      expect(find.text('500'), findsOneWidget);
      expect(changes.last, '500');
    });

    testWidgets('backspacing the minus leaves a positive amount',
        (tester) async {
      await pump(tester, type: TransactionKind.balanceAdjustment);

      await tester.enterText(find.byType(TextFormField), '-500');
      await tester.pump();

      // The minus is a character like any other, so deleting it is what makes
      // the amount positive again — no separate "switch the sign" gesture.
      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      controller.selection = const TextSelection.collapsed(offset: 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(find.text('500'), findsOneWidget);
      expect(changes.last, '500');
    });

    testWidgets('a negative is a valid amount', (tester) async {
      await pump(tester, type: TransactionKind.openingBalance);

      await tester.enterText(find.byType(TextFormField), '-500.00');
      await tester.pump();
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Invalid amount'), findsNothing);
    });

    testWidgets('an expense still refuses one', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField), '-500');
      await tester.pump();

      expect(find.text('-500'), findsNothing,
          reason: 'the formatter keeps the minus out of an unsigned field');
    });
  });
}
