/// Presentation-boundary money parsing/formatting (spec 003, US1/T014).
///
/// These are the only functions that turn user input into int minor units
/// and minor units into display strings. Everything below the presentation
/// layer works in int minor units (or `Money`) — never doubles.
library;

import 'package:feather_ledger/core/domain/money/money.dart';

/// Formats int minor units for display, e.g. `1234` → `"12.34"`.
///
/// **The minus belongs to the digits, not to the amount in a currency.** A
/// caller that puts a symbol in front of this gets `$-12.34`, which reads as a
/// symbol and then a negative number rather than a negative amount — use
/// [formatMinorWithSymbol] wherever there is a symbol to place.
String formatMinor(int minorUnits) => (minorUnits / 100).toStringAsFixed(2);

/// A signed amount with its currency, e.g. `- $12.34`.
///
/// The sign goes **outside** the symbol: `- $12.34`, never `$-12.34`. Every
/// amount that can legitimately be negative — an overdrawn balance, a credit
/// card's debt, an expense category's total — reads this way, and a positive
/// one is left alone rather than given a `+` it never had.
String formatMinorWithSymbol(int minorUnits, String currencySymbol) =>
    minorUnits < 0
        ? '- $currencySymbol${formatMinor(-minorUnits)}'
        : '$currencySymbol${formatMinor(minorUnits)}';

/// A signed amount with its currency symbol and ISO code, e.g.
/// `¥5000.00 JPY` or `- $12.34 USD`.
///
/// Only a mixed-currency list needs the code: two currencies (CNY and JPY)
/// share `¥`, and the code disambiguates. The sign stays outside the symbol,
/// as in [formatMinorWithSymbol].
String formatMinorWithSymbolAndCode(
        int minorUnits, String currencySymbol, String currencyCode) =>
    '${formatMinorWithSymbol(minorUnits, currencySymbol)} $currencyCode';

/// Parses validated user input (at most 2 decimals) into int minor units,
/// via the sanctioned [Money.fromDouble] bridge.
int parseMinor(String input) =>
    Money.fromDouble(double.parse(input), Money.defaultCurrencyCode).minorUnits;
