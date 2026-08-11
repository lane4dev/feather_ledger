import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/balance_visibility_provider.dart';
import 'package:feather_ledger/features/ledger/presentation/widgets/ledger_header.dart';
import 'package:feather_ledger/shared/presentation/models/monthly_summary_ui_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    final brightness = theme.brightness.name;
    test('$brightness surfaces keep text readable and charts independent', () {
      final scheme = theme.colorScheme;
      expect(contrast(scheme.onSurface, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onSurfaceVariant, scheme.surfaceContainerLow),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
          greaterThanOrEqualTo(4.5));
      expect(theme.extension<AppSemanticColors>()!.frequency,
          isNot(scheme.primary));
      expect(scheme.surface.r, scheme.surface.g);
      expect(scheme.surface.g, scheme.surface.b);
    });

    testWidgets(
        '$brightness shared controls preserve selection, disabled state and tap size',
        (tester) async {
      var taps = 0;
      var selected = 0;
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StatefulBuilder(
                builder: (context, setState) => Column(children: [
                      AppButton(
                          onPressed: () => taps++, child: const Text('Save')),
                      const AppButton(onPressed: null, child: Text('Disabled')),
                      AppIconButton.surface(
                          icon: const Icon(LucideIcons.search),
                          onPressed: () => taps++),
                      AppSegmentedControl<int>(
                        widthFactor: 1,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Income')),
                          ButtonSegment(value: 1, label: Text('Expense'))
                        ],
                        selected: selected,
                        onSelected: (value) => setState(() => selected = value),
                      ),
                      const AppCard(child: Text('A shared surface')),
                    ])),
          )));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.widgetWithText(FilledButton, 'Save')).height,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byType(IconButton)).width,
          greaterThanOrEqualTo(48));
      await tester.tap(find.text('Save'));
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(selected, 1);
      expect(
          tester
              .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
              .selected,
          {1});
      expect(tester.takeException(), isNull);
    });

    for (final locale in [
      const Locale('en'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
    ]) {
      testWidgets(
          '$brightness $locale summary fits a narrow screen with large text',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 760);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        const summary = MonthlySummaryUiModel(
            displayBalance: r'- $12345678901.23',
            displayIncome: r'$1234567.89',
            displayExpense: r'$9876543.21');
        await tester.pumpWidget(ProviderScope(
            overrides: [
              balanceVisibilityControllerProvider.overrideWith(_Visible.new)
            ],
            child: MaterialApp(
              theme: theme,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.8)),
                  child: child!),
              home: const Scaffold(
                  body: SingleChildScrollView(
                      child: LedgerHeader(summaryAsync: AsyncData(summary)))),
            )));
        await tester.pumpAndSettle();
        expect(find.text(summary.displayBalance), findsOneWidget);
        expect(find.byIcon(LucideIcons.eye), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('geometry and semantic colors interpolate for theme transitions', () {
    const original = AppMetrics();
    final larger = original.copyWith(cardRadius: 28, cellRadius: 8);
    final halfway = original.lerp(larger, 0.5);
    expect(halfway.cardRadius, 24);
    expect(halfway.cellRadius, 6);
    final light = AppTheme.lightTheme.extension<AppSemanticColors>()!;
    final dark = AppTheme.darkTheme.extension<AppSemanticColors>()!;
    expect(light.lerp(dark, 1).frequency, dark.frequency);
  });
}

class _Visible extends BalanceVisibilityController {
  @override
  Future<bool> build() async => true;
}
