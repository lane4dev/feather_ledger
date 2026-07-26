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

    // Widest, not first, not last, not the sum.
    expect(oneLongName, greaterThan(shortNames));
    // And the ceiling holds, so one word cannot take the row from the value.
    expect(absurd, LedgerTheme.formLabelMaxWidth);
  });
}
