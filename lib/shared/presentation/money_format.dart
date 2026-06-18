/// Presentation-boundary money parsing/formatting (spec 003, US1/T014).
///
/// These are the only functions that turn user input into int minor units
/// and minor units into display strings. Everything below the presentation
/// layer works in int minor units (or `Money`) — never doubles.
library;

import 'package:feather_ledger/core/domain/money/money.dart';

/// Formats int minor units for display, e.g. `1234` → `"12.34"`.
String formatMinor(int minorUnits) => (minorUnits / 100).toStringAsFixed(2);

/// Parses validated user input (at most 2 decimals) into int minor units,
/// via the sanctioned [Money.fromDouble] bridge.
int parseMinor(String input) =>
    Money.fromDouble(double.parse(input), Money.defaultCurrencyCode).minorUnits;
