import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_date_label.dart';

/// The date row's value (spec 004, US1). Pure function, so the day it is
/// written on is a parameter rather than the clock.
void main() {
  // The patterns are compiled in; the symbol map still has to be installed.
  // In the app `flutter_localizations` does this; here we do.
  setUpAll(initializeDateFormatting);

  final en = lookupAppLocalizations(const Locale('en'));
  final zh = lookupAppLocalizations(const Locale('zh'));

  final today = DateTime(2026, 9, 23, 14, 30);

  String label(DateTime date, {String locale = 'en', AppLocalizations? l10n}) =>
      transactionDateLabel(
        date: date,
        today: today,
        locale: locale,
        l10n: l10n ?? en,
      );

  test('names the day either side of today instead of dating it', () {
    expect(label(DateTime(2026, 9, 23, 9, 5)), 'Today 09:05');
    expect(label(DateTime(2026, 9, 22, 23, 59)), 'Yesterday 23:59');
    expect(label(DateTime(2026, 9, 24, 0, 1)), 'Tomorrow 00:01');
  });

  test('finds yesterday across a month and a year boundary', () {
    // The days either side are calendar neighbours, not a fixed number of
    // hours apart — which is what `difference().inDays` gets wrong on the day
    // a clock shifts, and what makes 1 January reach back into December.
    expect(
      transactionDateLabel(
        date: DateTime(2025, 12, 31, 8, 0),
        today: DateTime(2026, 1, 1, 8, 0),
        locale: 'en',
        l10n: en,
      ),
      'Yesterday 08:00',
    );
    expect(
      transactionDateLabel(
        date: DateTime(2026, 2, 28, 12, 0),
        today: DateTime(2026, 3, 1, 12, 0),
        locale: 'en',
        l10n: en,
      ),
      'Yesterday 12:00',
    );
  });

  test('leaves the year out inside the current one, and the weekday always',
      () {
    final sameYear = label(DateTime(2026, 1, 5, 15, 4));
    expect(sameYear, 'Jan 5 15:04');

    final otherYear = label(DateTime(2025, 1, 5, 15, 4));
    expect(otherYear, 'Jan 5, 2025 15:04');
  });

  test('is a 24-hour clock, whatever the locale prefers', () {
    // `jm` would render "3:04 PM" here. 23:45 is the case that shows it.
    expect(label(DateTime(2026, 1, 5, 23, 45)), 'Jan 5 23:45');
    expect(label(DateTime(2026, 1, 5, 23, 45)), isNot(contains('PM')));
  });

  test('takes the date pattern from the locale', () {
    expect(
      label(DateTime(2026, 9, 18, 14, 30), locale: 'zh', l10n: zh),
      '9月18日 14:30',
    );
    expect(
      label(DateTime(2025, 9, 18, 14, 30), locale: 'zh', l10n: zh),
      '2025年9月18日 14:30',
    );
    expect(
      label(DateTime(2026, 9, 23, 14, 30), locale: 'zh', l10n: zh),
      '今天 14:30',
    );
  });
}
