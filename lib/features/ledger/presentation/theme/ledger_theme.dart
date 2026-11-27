import 'package:flutter/material.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';

class LedgerTheme {
  const LedgerTheme._();

  // --- Layout Constants ---
  static const double colAnchorWidth = 56.0;
  static const double dayCardGap = 14.0;
  static const double rowMinHeight = 60.0;
  static const double rowVerticalPadding = 10.0;
  static const double rowTextGap = 2.0;
  static const double subtotalVerticalPadding = 6.0;
  static const double subtotalDividerAlpha = 0.45;
  static const double skippedTextAlpha = 0.58;
  static const double categoryAvatarSize = 40.0;

  // --- Overview card (hero) ---
  /// The gradient's top-left tint weight. Low enough that the colours are a
  /// cast over the surface rather than a second surface of their own.
  static const double overviewTintAlpha = 0.5;
  static const double overviewTintAlphaDark = 0.42;

  /// The bottom-right end. The card fades back into the plain surface, which
  /// is what keeps it from reading as a flat slab of colour.
  static const double overviewFloorAlpha = 0.06;

  /// The corner glow: present enough to catch the eye, never a spotlight.
  static const double overviewGlowAlpha = 0.10;
  static const double overviewGlowRadius = 1.05;

  /// The hairline. White picks out an edge on light surfaces; on dark ones it
  /// has to be nearly nothing or it reads as a chrome trim.
  static const double overviewBorderAlpha = 0.65;
  static const double overviewBorderAlphaDark = 0.07;
  static const double overviewBorderWidth = 1.0;

  /// Small enough to read as punctuation after the label, not as a button.
  static const double overviewChevronSize = 18.0;

  // --- Overview card footer (the merged income/expense bar) ---
  static const double footerBarAlpha = 0.5;
  static const double footerBarAlphaDark = 0.28;
  static const double footerDividerAlpha = 0.4;
  static const double footerIconSize = 32.0;
  static const double footerVerticalPadding = 10.0;

  // --- Overview card balance typesetting ---
  // The sizes themselves live in [AppTypography] because the budget overview
  // sets its hero amount the same way.
  static const double balanceSymbolSize = AppTypography.overviewSymbolSize;
  static const double balanceWholeSize = AppTypography.overviewWholeSize;
  static const double balanceFractionSize = AppTypography.overviewFractionSize;
  static const double balanceWholeTracking =
      AppTypography.overviewWholeTracking;

  /// The card's backplate: a soft diagonal mix of the scheme's own tones.
  ///
  /// Built from [ColorScheme.primaryContainer] over
  /// [ColorScheme.surfaceContainerHigh] at both ends, so a dynamic palette
  /// gets a tinted card and the fixed palettes get their familiar green — the
  /// two mixes differ, the recipe does not.
  static LinearGradient overviewBackdrop(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark) {
      // The light theme's hero is a physical brand card in deep teal: it is
      // the one surface that deliberately does not follow the white-card
      // hierarchy, so it reads as the account's headline rather than another
      // panel in the stack.
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF124F63), Color(0xFF1B3645)],
      );
    }
    const tintAlpha = overviewTintAlphaDark;
    final top = Color.alphaBlend(
      scheme.primaryContainer.withValues(alpha: tintAlpha),
      scheme.surfaceContainerHigh,
    );
    final bottom = Color.alphaBlend(
      scheme.primary.withValues(alpha: overviewFloorAlpha),
      scheme.surfaceContainer,
    );
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, scheme.surfaceContainerHigh, bottom],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  /// The corner highlight. Radial rather than linear so it has no edge of its
  /// own — it simply runs out.
  static RadialGradient overviewGlow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!dark) {
      return RadialGradient(
        center: const Alignment(0.82, -1.0),
        radius: overviewGlowRadius,
        colors: [
          const Color(0xFF9BE3F0).withValues(alpha: 0.14),
          const Color(0xFF9BE3F0).withValues(alpha: 0),
        ],
      );
    }
    return RadialGradient(
      center: const Alignment(0.82, -1.0),
      radius: overviewGlowRadius,
      colors: [
        scheme.primary.withValues(alpha: overviewGlowAlpha),
        scheme.primary.withValues(alpha: 0),
      ],
    );
  }

  /// The light hero's lift off the page. Dark keeps its flat plate.
  static List<BoxShadow>? overviewShadow(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) return null;
    return const [
      BoxShadow(
        color: Color(0x29124F63),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ];
  }

  /// Foreground roles while painting on the brand card. On light they are the
  /// card's own white ink, not the scheme's on-surface pair, which would be
  /// unreadable on deep teal.
  static Color overviewInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSurface
          : Colors.white;

  static Color overviewMutedInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : Colors.white.withValues(alpha: 0.72);

  static Color overviewFooterSurface(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.surface.withValues(alpha: footerBarAlphaDark)
        : Colors.white.withValues(alpha: 0.08);
  }

  static Color overviewFooterDivider(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.outlineVariant.withValues(alpha: footerDividerAlpha)
        : Colors.white.withValues(alpha: 0.18);
  }

  /// The icon disc inside the footer bar keeps the kind's colour on dark and
  /// becomes a translucent white lift on the brand card.
  static Color overviewChipFill(BuildContext context, Color darkColor) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkColor
          : Colors.white.withValues(alpha: 0.14);

  static Color overviewChipInk(BuildContext context, Color darkColor) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkColor
          : Colors.white;

  /// The expense sparkline is a soft coral glow on the teal card.
  static Color overviewSparkline(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).extension<AppSemanticColors>()!.expense
          : const Color(0xFFFFA28F);

  static Color overviewSparklineAxis(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.22);

  static Color overviewBorder(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return const Color(0xFFFFFFFF).withValues(
      alpha: dark ? overviewBorderAlphaDark : 0.12,
    );
  }

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
  static Color skippedColor(BuildContext context) => Theme.of(context)
      .colorScheme
      .onSurfaceVariant
      .withValues(alpha: skippedTextAlpha);
  static TextStyle collapsedTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          );
}
