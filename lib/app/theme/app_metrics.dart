import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Shared geometry. Feature-specific chart dimensions do not belong here.
@immutable
class AppMetrics extends ThemeExtension<AppMetrics> {
  const AppMetrics({
    this.cardRadius = 20,
    this.overviewCardRadius = 24,
    this.dayCardRadius = 18,
    this.subtleElevation = 1,
    this.cellRadius = 4,
    this.controlRadius = 14,
    this.selectionRadius = 10,
    this.chipRadius = 8,
    this.sheetRadius = 28,
    this.iconRadius = 12,
    this.cardInset = 20,
    this.rowInset = 12,
    this.controlHeight = 48,
    this.actionHeight = 52,
    this.iconSize = 20,
    this.pageGutter = 24,
    this.compactGutter = 16,
    this.sectionGap = 32,
    this.inlineBadgeGap = 6,
    this.compactBadgeMinHeight = 20,
    this.compactBadgeHorizontalPadding = 6,
    this.compactBadgeVerticalPadding = 2,
    this.compactBadgeIconSize = 11,
  });

  final double cardRadius;
  final double overviewCardRadius;
  final double dayCardRadius;
  final double subtleElevation;
  final double cellRadius;
  final double controlRadius;
  final double selectionRadius;
  final double chipRadius;
  final double sheetRadius;
  final double iconRadius;
  final double cardInset;
  final double rowInset;
  final double controlHeight;
  final double actionHeight;
  final double iconSize;
  final double pageGutter;
  final double compactGutter;
  final double sectionGap;
  final double inlineBadgeGap;
  final double compactBadgeMinHeight;
  final double compactBadgeHorizontalPadding;
  final double compactBadgeVerticalPadding;
  final double compactBadgeIconSize;

  BorderRadius get cellBorderRadius => BorderRadius.circular(cellRadius);
  BorderRadius get legendBorderRadius => BorderRadius.circular(cellRadius / 2);
  BorderRadius get dialogBorderRadius => BorderRadius.circular(sheetRadius);
  BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);
  BorderRadius get overviewCardBorderRadius =>
      BorderRadius.circular(overviewCardRadius);
  BorderRadius get dayCardBorderRadius => BorderRadius.circular(dayCardRadius);
  BorderRadius get controlBorderRadius => BorderRadius.circular(controlRadius);
  BorderRadius get selectionBorderRadius =>
      BorderRadius.circular(selectionRadius);
  BorderRadius get chipBorderRadius => BorderRadius.circular(chipRadius);
  BorderRadius get iconBorderRadius => BorderRadius.circular(iconRadius);
  BorderRadius get sheetBorderRadius =>
      BorderRadius.vertical(top: Radius.circular(sheetRadius));
  EdgeInsets get cardPadding => EdgeInsets.all(cardInset);
  EdgeInsets get fieldPadding =>
      EdgeInsets.symmetric(horizontal: compactGutter, vertical: rowInset);
  EdgeInsets get formIconPadding =>
      EdgeInsets.only(top: rowInset, right: pageGutter);

  @override
  AppMetrics copyWith({
    double? cardRadius,
    double? overviewCardRadius,
    double? dayCardRadius,
    double? subtleElevation,
    double? cellRadius,
    double? controlRadius,
    double? selectionRadius,
    double? chipRadius,
    double? sheetRadius,
    double? iconRadius,
    double? cardInset,
    double? rowInset,
    double? controlHeight,
    double? actionHeight,
    double? iconSize,
    double? pageGutter,
    double? compactGutter,
    double? sectionGap,
    double? inlineBadgeGap,
    double? compactBadgeMinHeight,
    double? compactBadgeHorizontalPadding,
    double? compactBadgeVerticalPadding,
    double? compactBadgeIconSize,
  }) =>
      AppMetrics(
        cardRadius: cardRadius ?? this.cardRadius,
        overviewCardRadius: overviewCardRadius ?? this.overviewCardRadius,
        dayCardRadius: dayCardRadius ?? this.dayCardRadius,
        subtleElevation: subtleElevation ?? this.subtleElevation,
        cellRadius: cellRadius ?? this.cellRadius,
        controlRadius: controlRadius ?? this.controlRadius,
        selectionRadius: selectionRadius ?? this.selectionRadius,
        chipRadius: chipRadius ?? this.chipRadius,
        sheetRadius: sheetRadius ?? this.sheetRadius,
        iconRadius: iconRadius ?? this.iconRadius,
        cardInset: cardInset ?? this.cardInset,
        rowInset: rowInset ?? this.rowInset,
        controlHeight: controlHeight ?? this.controlHeight,
        actionHeight: actionHeight ?? this.actionHeight,
        iconSize: iconSize ?? this.iconSize,
        pageGutter: pageGutter ?? this.pageGutter,
        compactGutter: compactGutter ?? this.compactGutter,
        sectionGap: sectionGap ?? this.sectionGap,
        inlineBadgeGap: inlineBadgeGap ?? this.inlineBadgeGap,
        compactBadgeMinHeight:
            compactBadgeMinHeight ?? this.compactBadgeMinHeight,
        compactBadgeHorizontalPadding:
            compactBadgeHorizontalPadding ?? this.compactBadgeHorizontalPadding,
        compactBadgeVerticalPadding:
            compactBadgeVerticalPadding ?? this.compactBadgeVerticalPadding,
        compactBadgeIconSize: compactBadgeIconSize ?? this.compactBadgeIconSize,
      );

  @override
  AppMetrics lerp(ThemeExtension<AppMetrics>? other, double t) {
    if (other is! AppMetrics) return this;
    return AppMetrics(
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      overviewCardRadius:
          lerpDouble(overviewCardRadius, other.overviewCardRadius, t)!,
      dayCardRadius: lerpDouble(dayCardRadius, other.dayCardRadius, t)!,
      subtleElevation: lerpDouble(subtleElevation, other.subtleElevation, t)!,
      cellRadius: lerpDouble(cellRadius, other.cellRadius, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      selectionRadius: lerpDouble(selectionRadius, other.selectionRadius, t)!,
      chipRadius: lerpDouble(chipRadius, other.chipRadius, t)!,
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t)!,
      iconRadius: lerpDouble(iconRadius, other.iconRadius, t)!,
      cardInset: lerpDouble(cardInset, other.cardInset, t)!,
      rowInset: lerpDouble(rowInset, other.rowInset, t)!,
      controlHeight: lerpDouble(controlHeight, other.controlHeight, t)!,
      actionHeight: lerpDouble(actionHeight, other.actionHeight, t)!,
      iconSize: lerpDouble(iconSize, other.iconSize, t)!,
      pageGutter: lerpDouble(pageGutter, other.pageGutter, t)!,
      compactGutter: lerpDouble(compactGutter, other.compactGutter, t)!,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t)!,
      inlineBadgeGap: lerpDouble(inlineBadgeGap, other.inlineBadgeGap, t)!,
      compactBadgeMinHeight:
          lerpDouble(compactBadgeMinHeight, other.compactBadgeMinHeight, t)!,
      compactBadgeHorizontalPadding: lerpDouble(compactBadgeHorizontalPadding,
          other.compactBadgeHorizontalPadding, t)!,
      compactBadgeVerticalPadding: lerpDouble(
          compactBadgeVerticalPadding, other.compactBadgeVerticalPadding, t)!,
      compactBadgeIconSize:
          lerpDouble(compactBadgeIconSize, other.compactBadgeIconSize, t)!,
    );
  }
}

extension AppMetricsX on BuildContext {
  AppMetrics get metrics =>
      Theme.of(this).extension<AppMetrics>() ?? const AppMetrics();

  EdgeInsets get pagePadding => EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(this).width <= 360
          ? metrics.compactGutter
          : metrics.pageGutter);
}
