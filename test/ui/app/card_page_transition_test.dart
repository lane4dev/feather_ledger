import 'package:feather_ledger/app/router/card_page_transition.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a missing source fades the page', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const CardPageTransition(
        animation: AlwaysStoppedAnimation(0.5),
        sourceKey: null,
        child: Text('Report'),
      ),
    ));

    final opacity = tester.widget<Opacity>(find.descendant(
      of: find.byType(CardPageTransition),
      matching: find.byType(Opacity),
    ));
    expect(opacity.opacity, greaterThan(0));
    expect(opacity.opacity, lessThan(1));
    expect(find.byKey(const ValueKey('report-transition-surface')), findsNothing);
  });

  testWidgets('reduced motion displays the page without a transition',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: CardPageTransition(
          animation: AlwaysStoppedAnimation(0.0),
          sourceKey: null,
          child: Text('Report'),
        ),
      ),
    ));

    expect(find.text('Report'), findsOneWidget);
    expect(
        find.descendant(
          of: find.byType(CardPageTransition),
          matching: find.byType(Opacity),
        ),
        findsNothing);
  });
}
