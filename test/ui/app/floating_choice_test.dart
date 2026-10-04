import 'package:feather_ledger/app/design_system/app_choice_chips.dart';
import 'package:feather_ledger/app/design_system/app_floating_toolbar.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('floating choice uses compact width at normal text scale',
      (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: AppFloatingToolbar(
            child: AppChoiceChips<bool>.floating(
              choices: const [
                ButtonSegment(value: false, label: Text('Budget tracking')),
                ButtonSegment(value: true, label: Text('Review preview')),
              ],
              selected: false,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppFloatingToolbar)).width, 232);
    expect(tester.getSize(find.byType(AppFloatingToolbar)).height, 48);
  });

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets('floating choice fits and moves in ${theme.brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var selected = false;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(builder: (context, setState) {
              return AppFloatingToolbar(
                child: AppChoiceChips<bool>.floating(
                  choices: const [
                    ButtonSegment(value: false, label: Text('Budget tracking')),
                    ButtonSegment(value: true, label: Text('Review preview')),
                  ],
                  selected: selected,
                  onSelected: (value) => setState(() => selected = value),
                ),
              );
            }),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final indicator = find.byKey(const ValueKey('floating-choice-indicator'));
      final before = tester.getCenter(indicator);
      final choices = find.descendant(
        of: find.byType(AppChoiceChips<bool>),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(choices.first).width,
          tester.getSize(choices.last).width);
      expect(tester.getSize(choices.first).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Review preview'));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
      expect(tester.getCenter(indicator).dx, greaterThan(before.dx));
      expect(tester.takeException(), isNull);
    });
  }
}
