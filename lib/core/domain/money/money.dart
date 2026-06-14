/// Immutable `Money` value object (spec 003, Domain Model / Money).
///
/// All ledger amounts are int minor units (cents) — `double`/`float` is
/// banned from every accounting path. `Money` exists to make currency
/// mistakes loud: mixing currencies in one arithmetic operation throws
/// [CurrencyMismatchError] instead of silently merging balances.
///
/// Formatting (symbol placement, decimal digits, display currency
/// preference) is a *presentation* concern and deliberately not here.
library;

/// Thrown when two `Money`s of different currencies are combined.
class CurrencyMismatchError extends Error {
  final String left;
  final String right;

  CurrencyMismatchError(this.left, this.right);

  @override
  String toString() =>
      'CurrencyMismatchError: cannot combine $left with $right';
}

/// Thrown when constructing `Money` from a non-finite or non-integral
/// double — the only sanctioned bridge from UI input, which must itself
/// already be exact to the minor unit.
class InexactAmountError extends Error {
  final double value;

  InexactAmountError(this.value);

  @override
  String toString() =>
      'InexactAmountError: $value is not an exact number of minor units';
}

class Money {
  /// ISO 4217-style currency code, e.g. `USD`, `CNY`.
  final String currencyCode;

  /// Amount in minor units (cents). Negative = outflow direction context.
  final int minorUnits;

  const Money(this.minorUnits, this.currencyCode);

  Money.zero(this.currencyCode) : minorUnits = 0;

  static const String defaultCurrencyCode = 'USD';

  /// The only double→Money bridge in the codebase. Presentation layers use
  /// it at the input boundary; domain code receives `Money` or raw int
  /// minor units, never doubles.
  factory Money.fromDouble(double amount, String currencyCode) {
    if (amount.isInfinite || amount.isNaN) {
      throw InexactAmountError(amount);
    }
    final units = amount * 100;
    if ((units - units.roundToDouble()).abs() > 1e-9) {
      throw InexactAmountError(amount);
    }
    return Money(units.round(), currencyCode);
  }

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currencyCode);
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currencyCode);
  }

  Money operator -() => Money(-minorUnits, currencyCode);

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);

  @override
  String toString() => '$minorUnits $currencyCode';

  void _requireSameCurrency(Money other) {
    if (other.currencyCode != currencyCode) {
      throw CurrencyMismatchError(currencyCode, other.currencyCode);
    }
  }
}
