import 'package:flutter/material.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';

class LedgerTheme {
  const LedgerTheme._();

  // --- Layout Constants ---
  static const double colAnchorWidth = 56.0;
  static const double dayCardGap = 14.0;
  static const double rowMinHeight = 62.0;
  static const double categoryAvatarSize = 40.0;

  /// The ceiling on the field-name column in the transaction form. The column
  /// is measured from the labels the form actually shows in the language being
  /// read ([formLabelWidth]), not fixed: a name must be as wide as it needs to
  /// be, or a language whose words are longer than the box has its field names
  /// cut off. The ceiling is what keeps a single long name from eating the
  /// value's half of the row.
  static const double formLabelMaxWidth = 104.0;

  /// The gap between that column and the value.
  static const double formLabelGap = 12.0;

  /// Both recorded and pending editors use the same column, even when a
  /// particular editor does not offer every field.
  static double transactionFormLabelWidth(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return formLabelWidth(context, [
      l10n.transactionType,
      l10n.date,
      l10n.repeat,
      l10n.account,
      l10n.transferFrom,
      l10n.transferTo,
      l10n.category,
      l10n.note,
      l10n.attachments,
    ]);
  }

  /// The page's horizontal margin.
  ///
  /// A form row applies it to its own contents rather than having its screen
  /// apply it from outside: the row's tap target has to reach the screen edge
  /// for its ripple to, and padding applied around a row clips that ripple.
  /// Whatever a screen puts in the same column that is *not* a row is the
  /// screen's to inset — by this.
  static EdgeInsets pageInset(BuildContext context) => context.pagePadding;

  /// The width of the field-name column: the widest of [labels] as it will be
  /// drawn, capped at [formLabelMaxWidth].
  ///
  /// Pass every name the screen can show, not just the ones rendered right
  /// now — the column is shared by all of a form's rows, so a width that
  /// changed with the state would move every value's starting x mid-form.
  ///
  /// The measurement has to match how the label is painted or the column
  /// silently under-reserves: the same style, the same text scale, the same
  /// direction, and no max width (the question is what one unbroken line
  /// needs, and [TextPainter.width] answers that only when unconstrained).
  static double formLabelWidth(BuildContext context, Iterable<String> labels) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge!;
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final locale = Localizations.localeOf(context);

    var widest = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
      )..layout();
      // Round up: landing a hair under the painted width ellipsizes a label
      // that would have fitted.
      final width = painter.width.ceilToDouble();
      painter.dispose();
      if (width > widest) widest = width;
    }
    return widest < formLabelMaxWidth ? widest : formLabelMaxWidth;
  }

  /// Placeholder fill for loading skeletons: a translucent neutral that
  /// follows the surface lightness instead of a fixed grey.
  static Color skeletonFill(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

  // Compatibility roles delegate to the global typography system.
  static TextStyle anchorDayText(BuildContext context) =>
      AppTypography.sectionTitle(context);
  static TextStyle anchorWeekdayText(BuildContext context) =>
      AppTypography.meta(context);
  static TextStyle transactionAmount(BuildContext context) =>
      AppTypography.amount(context);
  static TextStyle transactionTitle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;
  static TextStyle transactionMeta(BuildContext context) =>
      AppTypography.meta(context);
  static TextStyle denseLabel(BuildContext context) =>
      AppTypography.compactLabel(context);
  static TextStyle overviewBalance(BuildContext context) =>
      AppTypography.balance(context).copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );
}
