import 'package:flutter/material.dart';

class LedgerTheme {
  const LedgerTheme._();

  // --- Spacing (Gaps) ---
  static const double gapXs = 4.0;
  static const double gapSm = 8.0;
  static const double gapMd = 16.0;
  static const double gapLg = 24.0;

  // --- Layout Constants ---
  static const double colAnchorWidth = 72.0;
  static const double cardRadius = 16.0;

  // --- Typography Helpers (Roles) ---
  static TextStyle balanceText(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
        );
  }

  static TextStyle balanceLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!;
  }

  static TextStyle anchorDayText(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
        );
  }

  static TextStyle anchorWeekdayText(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }

  static TextStyle transactionAmount(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
          // monospacedDigit is optional but good for alignment
          fontFeatures: const [FontFeature.tabularFigures()],
        );
  }

  static TextStyle transactionTitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!;
  }

  static TextStyle transactionMeta(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }

  // --- Color Helpers ---
  static Color incomeColor(BuildContext context) {
    // Green-aligned
    return Colors.green; // Or Theme.of(context).colorScheme.tertiary if configured green
  }

  static Color expenseColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }
}
