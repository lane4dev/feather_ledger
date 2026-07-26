import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_selector_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget field) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SizedBox(width: 300, child: field))),
      );

  testWidgets('an unlabelled field keeps its value on the leading edge',
      (tester) async {
    await pump(tester, LedgerSelectorField(text: 'Cash', onTap: () {}));

    // Without a label the value *is* the field's name, so it sits where the
    // name sits and the spacer belongs between it and the chevron. The two
    // unlabelled callers — the recurring bill form and the filter sheet —
    // never opted into the labelled layout, and a spacer placed *before* the
    // value parks it in the middle of the row with the chevron short of the
    // trailing edge.
    expect(tester.getTopLeft(find.text('Cash')).dx, 0);
    expect(
      tester.getTopRight(find.byIcon(LucideIcons.chevronRight)).dx,
      300,
    );
  });

  testWidgets('a labelled field separates the name from the value',
      (tester) async {
    await pump(
      tester,
      LedgerSelectorField(label: 'Account', text: 'Cash', onTap: () {}),
    );

    expect(tester.getTopLeft(find.text('Account')).dx, 0);
    expect(
      tester.getTopLeft(find.text('Cash')).dx,
      greaterThan(tester.getTopLeft(find.text('Account')).dx),
    );
  });
}
