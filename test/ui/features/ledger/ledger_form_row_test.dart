import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_form_row.dart';

/// One line of a form: [Icon] [field] [>].
///
/// What matters here is where the tap goes. The row owns it, so the icon is
/// part of the target and the ripple is the whole line — a field that carried
/// its own tap made the icon dead and started the ripple halfway across. The
/// contents are inset from the page edge; the ripple is not.
void main() {
  Future<void> pump(WidgetTester tester, Widget row) => tester.pumpWidget(
        MaterialApp(
          // The row reads `context.spacing` for its content padding.
          theme: AppTheme.lightTheme,
          home: Scaffold(body: SizedBox(width: 300, child: row)),
        ),
      );

  testWidgets('the row is the tap target, icon included', (tester) async {
    var taps = 0;
    await pump(
      tester,
      LedgerFormRow(
        icon: LucideIcons.clock,
        onTap: () => taps++,
        child: const Text('Today 15:04'),
      ),
    );

    final ink = find.byType(InkWell);
    expect(
      find.descendant(
        of: ink,
        matching: find.byIcon(LucideIcons.clock),
      ),
      findsOneWidget,
      reason: 'the icon is inside the tap target, not beside it',
    );
    expect(tester.getTopLeft(ink).dx, 0);
    expect(tester.getTopRight(ink).dx, 300,
        reason: 'the ripple reaches both edges of the row');

    // ...while the contents keep the page's margin. The margin is inside the
    // tap target on purpose: a screen that pads its rows instead of letting
    // them pad themselves clips every ripple one page margin short.
    expect(tester.getTopLeft(find.byIcon(LucideIcons.clock)).dx,
        AppTheme.spacing.lg);

    await tester.tap(find.byIcon(LucideIcons.clock));
    expect(taps, 1, reason: 'tapping the icon opens the field');
  });

  testWidgets('a row that opens something says so', (tester) async {
    await pump(
      tester,
      LedgerFormRow(
        icon: LucideIcons.clock,
        onTap: () {},
        child: const Text('Today 15:04'),
      ),
    );

    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets('a row that opens nothing is not a tap target', (tester) async {
    // The note row is typed in, and the read-only rows state a fact; a
    // chevron on either would promise an action that does not exist.
    await pump(
      tester,
      const LedgerFormRow(
        icon: LucideIcons.stickyNote,
        child: Text('Note'),
      ),
    );

    expect(find.text('Note'), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });
}
