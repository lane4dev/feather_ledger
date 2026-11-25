/// A written-out amount, taken apart for three-tier setting.
///
/// The overview card sets the currency symbol, the integer part and the
/// decimals at three different sizes, which means it needs them as three
/// strings. It reads them off the **already formatted** amount rather than
/// building them from minor units: formatting is [formatMinorWithSymbol]'s
/// job, and a card that re-derived the digits would be a second answer to
/// "how is money written" — the one thing the presentation boundary exists to
/// keep single.
///
/// The split is deliberately dumb: sign, then whatever stands in front of the
/// digits (the symbol, which may itself be several characters), then the digits
/// and the fraction at the last `.`.
class BalanceDisplayParts {
  /// `''` or `'-'`. The minus stays outside the symbol, as everywhere else.
  final String sign;
  final String symbol;

  /// Everything before the decimal point, grouping included — or the whole
  /// string when it has no decimal point.
  final String whole;

  /// `.00`, or `''` when the amount was not written with decimals.
  final String fraction;

  const BalanceDisplayParts({
    required this.sign,
    required this.symbol,
    required this.whole,
    required this.fraction,
  });

  /// True when [source] was not a number at all (`—`, `******`), in which case
  /// there is nothing to set at three sizes.
  bool get isNumeric => whole.isNotEmpty && symbol.isNotEmpty;

  static BalanceDisplayParts parse(String source) {
    var rest = source;
    var sign = '';
    if (rest.startsWith('-')) {
      sign = '-';
      rest = rest.substring(1);
    } else if (rest.startsWith('+')) {
      rest = rest.substring(1);
    }

    // The symbol runs until the first character that can only be part of a
    // number. Some currencies write it as letters ("USD "), so this must not
    // assume a single glyph.
    final firstDigit = rest.indexOf(RegExp(r'[0-9]'));
    if (firstDigit < 0) {
      return BalanceDisplayParts(
        sign: sign,
        symbol: '',
        whole: source,
        fraction: '',
      );
    }
    final symbol = rest.substring(0, firstDigit);
    final number = rest.substring(firstDigit);

    final dot = number.lastIndexOf('.');
    if (dot < 0) {
      return BalanceDisplayParts(
        sign: sign,
        symbol: symbol,
        whole: number,
        fraction: '',
      );
    }
    return BalanceDisplayParts(
      sign: sign,
      symbol: symbol,
      whole: number.substring(0, dot),
      fraction: number.substring(dot),
    );
  }
}
