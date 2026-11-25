import 'package:flutter/material.dart';

/// Shared visual roles; formatted values and business meaning stay with callers.
abstract final class AppTypography {
  /// The three sizes an overview amount is set at: symbol, whole units, then
  /// the decimals. The digits that carry the magnitude are the ones read at a
  /// glance; the cents step back into the supporting colour.
  ///
  /// Shared by the ledger header and the budget overview so the two hero
  /// numbers typeset alike instead of drifting apart one edit at a time.
  static const double overviewSymbolSize = 20.0;
  static const double overviewWholeSize = 36.0;
  static const double overviewFractionSize = 22.0;
  static const double overviewWholeTracking = -0.5;

  static TextStyle balance(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineLarge!
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle amount(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle statistic(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineSmall!
      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle amountInput(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!.copyWith(
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle sectionTitle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium!
      .copyWith(fontWeight: FontWeight.w600);
  static TextStyle selectedLabel(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyLarge!
      .copyWith(fontWeight: FontWeight.w600);
  static TextStyle meta(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall!
      .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
  static TextStyle compactLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!;
  static TextStyle compactAmount(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()]);
  static TextStyle chartLabel(BuildContext context,
          {bool emphasized = false}) =>
      (emphasized
              ? Theme.of(context).textTheme.bodySmall!
              : compactLabel(context))
          .copyWith(fontWeight: FontWeight.w600);
}
