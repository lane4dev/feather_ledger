import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/features/ledger/presentation/models/custom_recurrence.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/custom_recurrence_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('zh', 'CN')]) {
    testWidgets('custom repeat fits a narrow screen in $locale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
            builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.2)),
                  child: Scaffold(
                      body: Center(
                          child: CustomRecurrenceDialog(
                    initial: CustomRecurrence(
                        frequency: 'WEEKLY',
                        interval: 1,
                        startDate: DateTime(2026, 11, 14),
                        weekdays: const [6]),
                  ))),
                )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
      final monday = find.byKey(const ValueKey('weekday-1'));
      final sunday = find.byKey(const ValueKey('weekday-7'));
      expect(tester.getTopLeft(monday).dy, tester.getTopLeft(sunday).dy);
      await tester.drag(
          find.byKey(const ValueKey('weekdays-scroll')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(sunday);
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(sunday).selected, isTrue);
      final countOption = find.byWidgetPredicate(
          (widget) => widget is Radio<int> && widget.value == 2);
      await tester.scrollUntilVisible(countOption, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(countOption);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
