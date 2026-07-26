import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';

/// The value column of a form row. It draws and nothing else — the ripple and
/// the chevron belong to the row around it (see `ledger_form_row_test.dart`).
///
/// The contract that matters: every row of a form shows its value at the same
/// x, whatever its field name says and whichever language says it, and the
/// name never wraps its way into a second line.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SizedBox(width: 300, child: child))),
      );

  testWidgets('a labelled field puts every value in the same column',
      (tester) async {
    await pump(
      tester,
      const Column(
        children: [
          LedgerSelectorField(label: 'Account', labelWidth: 96, text: 'Cash'),
          LedgerSelectorField(label: 'Category', labelWidth: 96, text: 'Food'),
        ],
      ),
    );

    // The name's column is a width the caller measured, not a measurement of
    // whichever name this row happens to carry, so a longer word in one row
    // cannot push the values out of line.
    expect(tester.getTopLeft(find.text('Account')).dx, 0);
    expect(
      tester.getTopLeft(find.text('Cash')).dx,
      96 + LedgerTheme.formLabelGap,
    );
    expect(
      tester.getTopLeft(find.text('Food')).dx,
      tester.getTopLeft(find.text('Cash')).dx,
    );
  });

  testWidgets('an unlabelled field puts its value on the leading edge',
      (tester) async {
    await pump(tester, const LedgerSelectorField(text: 'Cash'));

    expect(tester.getTopLeft(find.text('Cash')).dx, 0);
    expect(tester.getSize(find.text('Cash')).width, 300,
        reason: 'the value is the row, so it takes the row');
  });

  testWidgets('a name too long for its column is cut, not wrapped',
      (tester) async {
    await pump(
      tester,
      const LedgerSelectorField(
        label: 'A field name far too long for the column it was given',
        labelWidth: 96,
        text: 'Value',
      ),
    );

    final name = tester.widget<Text>(
      find.text('A field name far too long for the column it was given'),
    );
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);

    // And it stays one line tall: the value is what gives when the row is
    // narrow, never the name.
    expect(
      tester.getSize(find.text('A field name far too long for the column it '
              'was given')).height,
      tester.getSize(find.text('Value')).height,
    );
  });
}
