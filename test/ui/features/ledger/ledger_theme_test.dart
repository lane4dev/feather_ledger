import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/features/ledger/presentation/theme/ledger_theme.dart';

/// The field-name column: the widest name a form shows, and a ceiling on it.
void main() {
  testWidgets('the column is the widest name it was given, capped',
      (tester) async {
    late double shortNames;
    late double oneLongName;
    late double absurd;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            shortNames = LedgerTheme.formLabelWidth(context, ['Date', 'Note']);
            oneLongName = LedgerTheme.formLabelWidth(context, ['Attachments']);
            absurd = LedgerTheme.formLabelWidth(
              context,
              ['A field name longer than any form has any business showing'],
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    //Widest, not first, not last, not the sum.
    expect(oneLongName, greaterThan(shortNames));
    // And the ceiling holds, so one word cannot take the row from the value.
    expect(absurd, LedgerTheme.formLabelMaxWidth);
  });

  testWidgets('layout constants and tabular amount style match Ticket 04 bounds',
      (tester) async {
    late TextStyle amountStyle;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            amountStyle = LedgerTheme.transactionAmount(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(LedgerTheme.colAnchorWidth, inInclusiveRange(52.0, 56.0));
    expect(LedgerTheme.dayCardGap, inInclusiveRange(12.0, 16.0));
    expect(LedgerTheme.rowMinHeight, inInclusiveRange(60.0, 68.0));
    expect(LedgerTheme.categoryAvatarSize, inInclusiveRange(36.0, 40.0));
    expect(
      amountStyle.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
