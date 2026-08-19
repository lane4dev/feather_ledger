import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('scrollable choices stay on one row and the last can be selected',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
          body: Center(
              child: StatefulBuilder(
        builder: (context, setState) => AppChoiceChips<int>(
          scrollable: true,
          choices: const [
            ButtonSegment(value: 0, label: Text('Default')),
            ButtonSegment(value: 1, label: Text('Planned')),
            ButtonSegment(value: 2, label: Text('Subscription')),
            ButtonSegment(value: 3, label: Text('Repeating')),
          ],
          selected: selected,
          onSelected: (value) => setState(() => selected = value),
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(tester.getTopLeft(find.text('Default')).dy,
        tester.getTopLeft(find.text('Repeating')).dy);
    await tester.drag(find.byKey(const ValueKey('choice-chips-scroll')),
        const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeating'));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets('arrows appear only when the choices do not fit', (tester) async {
    var width = 700.0;
    var selected = 0;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
          body: Center(child: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return SizedBox(
            width: width,
            child: AppChoiceChips<int>(
              scrollable: true,
              choices: const [
                ButtonSegment(value: 0, label: Text('Default')),
                ButtonSegment(value: 1, label: Text('Planned')),
                ButtonSegment(value: 2, label: Text('Subscription')),
                ButtonSegment(value: 3, label: Text('Repeating')),
              ],
              selected: selected,
              onSelected: (value) => setState(() => selected = value),
            ));
      }))),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    await tester.tap(find.text('Planned'));
    update(() => width = 260);
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    expect(selected, 1);
    update(() => width = 700);
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    expect(selected, 1);
  });
}
