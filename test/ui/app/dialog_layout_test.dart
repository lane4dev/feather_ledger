import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/presentation/providers/currency_provider.dart';
import 'package:feather_ledger/core/presentation/providers/locale_provider.dart';
import 'package:feather_ledger/core/presentation/providers/theme_provider.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    ThemeData theme,
    double width,
    Widget home,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        themeModeControllerProvider.overrideWith(_FixedTheme.new),
        localeControllerProvider.overrideWith(_FixedLocale.new),
        currencyControllerProvider.overrideWith(_FixedCurrency.new),
      ],
      child: MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  void expectWidth(WidgetTester tester, double viewportWidth) {
    final surface = find
        .descendant(
          of: find.byType(Dialog),
          matching: find.byType(Material),
        )
        .first;
    final expected = math.min(viewportWidth - 32, 560);
    expect(tester.getSize(surface).width, closeTo(expected, 0.01));
    expect(tester.getTopLeft(surface).dx,
        closeTo((viewportWidth - expected) / 2, 0.01));
    expect(tester.takeException(), isNull);
  }

  Future<void> dismiss(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(Dialog))).pop();
    await tester.pumpAndSettle();
  }

  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    for (final width in [320.0, 390.0, 1024.0]) {
      testWidgets(
          '${theme.brightness.name} settings menus fill the same width at $width',
          (tester) async {
        await pump(tester, theme, width, const SettingsScreen());
        for (final label in ['Theme', 'Language', 'Currency Symbol']) {
          await tester.tap(find.widgetWithText(ListTile, label));
          await tester.pumpAndSettle();
          expectWidth(tester, width);
          await dismiss(tester);
        }
      });

      testWidgets(
          '${theme.brightness.name} confirmations and pickers fill the same width at $width',
          (tester) async {
        final date = DateTime(2026, 11, 13);
        await pump(
            tester,
            theme,
            width,
            Builder(
                builder: (context) => Scaffold(
                      body: Column(children: [
                        TextButton(
                            onPressed: () => showDialog<void>(
                                context: context,
                                builder: (context) => const AlertDialog(
                                    title: Text('Confirm'),
                                    content: Text('OK?'))),
                            child: const Text('Confirmation')),
                        TextButton(
                            onPressed: () => FeatherMonthPicker.show(context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                onMonthSelected: (_) {}),
                            child: const Text('Month')),
                        TextButton(
                            onPressed: () => showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030)),
                            child: const Text('Date')),
                        TextButton(
                            onPressed: () => showTimePicker(
                                context: context,
                                initialTime:
                                    const TimeOfDay(hour: 9, minute: 30)),
                            child: const Text('Time')),
                      ]),
                    )));
        for (final label in ['Confirmation', 'Month', 'Date', 'Time']) {
          await tester.tap(find.widgetWithText(TextButton, label));
          await tester.pumpAndSettle();
          expectWidth(tester, width);
          await dismiss(tester);
        }
      });
    }
  }
}

class _FixedTheme extends ThemeModeController {
  @override
  Future<ThemeMode> build() async => ThemeMode.system;
}

class _FixedLocale extends LocaleController {
  @override
  Future<Locale?> build() async => null;
}

class _FixedCurrency extends CurrencyController {
  @override
  Future<String> build() async => 'USD';
}
