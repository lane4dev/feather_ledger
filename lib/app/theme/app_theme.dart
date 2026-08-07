import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'account_card_theme.dart';
import 'app_metrics.dart';

export 'app_metrics.dart';
export 'app_typography.dart';

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }

    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.income,
    required this.expense,
    required this.frequency,
  });

  final Color income;
  final Color expense;
  final Color frequency;

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? frequency,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      frequency: frequency ?? this.frequency,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      frequency: Color.lerp(frequency, other.frequency, t) ?? frequency,
    );
  }
}

class AppTheme {
  static const spacing = AppSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);
  static const metrics = AppMetrics();

  static const _semanticsLight = AppSemanticColors(
    income: Color(0xFF0F766E),
    expense: Color(0xFFC2410C),
    frequency: Color(0xFF665BD8),
  );
  static const _semanticsDark = AppSemanticColors(
    income: Color(0xFF81C995),
    expense: Color(0xFFFFB4AB),
    frequency: Color(0xFFB6AEFF),
  );

  static const textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w500),
    displayMedium: TextStyle(fontSize: 42, fontWeight: FontWeight.w500),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w500),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge:
        TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium:
        TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
    bodySmall:
        TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  static final lightTheme = _build(Brightness.light);
  static final darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF386A63),
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFFF2F2F2) : const Color(0xFF171717),
      onPrimary: dark ? const Color(0xFF171717) : const Color(0xFFFFFFFF),
      primaryContainer:
          dark ? const Color(0xFF353535) : const Color(0xFFEAEAEA),
      onPrimaryContainer:
          dark ? const Color(0xFFF2F2F2) : const Color(0xFF171717),
      secondary: dark ? const Color(0xFFCCCCCC) : const Color(0xFF505050),
      onSecondary: dark ? const Color(0xFF171717) : const Color(0xFFFFFFFF),
      secondaryContainer:
          dark ? const Color(0xFF383838) : const Color(0xFFE7E7E7),
      onSecondaryContainer:
          dark ? const Color(0xFFF2F2F2) : const Color(0xFF171717),
      surface: dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
      surfaceDim: dark ? const Color(0xFF121212) : const Color(0xFFE4E4E4),
      surfaceBright: dark ? const Color(0xFF353535) : const Color(0xFFFFFFFF),
      surfaceContainerLowest:
          dark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF1C1C1C) : const Color(0xFFF6F6F6),
      surfaceContainer:
          dark ? const Color(0xFF222222) : const Color(0xFFF2F2F2),
      surfaceContainerHigh:
          dark ? const Color(0xFF282828) : const Color(0xFFEEEEEE),
      surfaceContainerHighest:
          dark ? const Color(0xFF303030) : const Color(0xFFE8E8E8),
      onSurface: dark ? const Color(0xFFF2F2F2) : const Color(0xFF171717),
      onSurfaceVariant:
          dark ? const Color(0xFFB0B0B0) : const Color(0xFF686868),
      outline: dark ? const Color(0xFF777777) : const Color(0xFF888888),
      outlineVariant: dark ? const Color(0xFF383838) : const Color(0xFFE3E3E3),
      inverseSurface: dark ? const Color(0xFFF2F2F2) : const Color(0xFF242424),
      onInverseSurface:
          dark ? const Color(0xFF171717) : const Color(0xFFF2F2F2),
      inversePrimary: dark ? const Color(0xFF171717) : const Color(0xFFF2F2F2),
      surfaceTint: dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
    );
    // Resolve platform font families and foreground colors once before using
    // the same roles in Material component themes.
    final typography = ThemeData(
            useMaterial3: true,
            brightness: brightness,
            colorScheme: scheme,
            textTheme: textTheme)
        .textTheme;
    final controlShape =
        RoundedRectangleBorder(borderRadius: metrics.controlBorderRadius);
    final fieldBorder = OutlineInputBorder(
        borderRadius: metrics.controlBorderRadius, borderSide: BorderSide.none);
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: Size(metrics.controlHeight, metrics.controlHeight),
      shape: controlShape,
      padding:
          EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
      textStyle: typography.labelLarge,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: typography,
      dividerColor: scheme.outlineVariant,
      extensions: <ThemeExtension<dynamic>>[
        spacing,
        metrics,
        dark ? _semanticsDark : _semanticsLight,
        dark ? AccountCardTheme.dark : AccountCardTheme.light,
      ],
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle:
            typography.titleLarge!.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: metrics.cardBorderRadius),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: Size(metrics.controlHeight, metrics.controlHeight),
        shape: controlShape,
        side: BorderSide(color: scheme.outlineVariant),
        padding:
            EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
        textStyle: typography.labelLarge,
      )),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        foregroundColor: scheme.onSurface,
        shape: controlShape,
        minimumSize: Size(metrics.controlHeight, metrics.controlHeight),
        textStyle: typography.labelLarge,
      )),
      iconTheme:
          IconThemeData(size: metrics.iconSize, color: scheme.onSurfaceVariant),
      iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.square(metrics.controlHeight)),
        iconSize: WidgetStatePropertyAll(metrics.iconSize),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.38)
                : scheme.onSurfaceVariant),
      )),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder:
            fieldBorder.copyWith(borderSide: BorderSide(color: scheme.primary)),
        errorBorder:
            fieldBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: fieldBorder.copyWith(
            borderSide: BorderSide(color: scheme.error, width: 2)),
        contentPadding: metrics.fieldPadding,
        hintStyle:
            typography.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
        minVerticalPadding: spacing.sm,
        horizontalTitleGap: spacing.md,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: typography.bodyLarge!.copyWith(color: scheme.onSurface),
        subtitleTextStyle:
            typography.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
        selectedColor: scheme.onSecondaryContainer,
        selectedTileColor: scheme.secondaryContainer,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            size: metrics.iconSize,
            color: states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            typography.labelMedium!.copyWith(
                color: states.contains(WidgetState.selected)
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: metrics.subtleElevation,
        shape: RoundedRectangleBorder(borderRadius: metrics.cardBorderRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: metrics.sheetBorderRadius),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        insetPadding:
            EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.lg),
        // Fill the available width on phones; keep a shared desktop ceiling.
        constraints: const BoxConstraints.tightFor(width: 560),
        shape: RoundedRectangleBorder(borderRadius: metrics.dialogBorderRadius),
      ),
      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide.none,
        shape:
            RoundedRectangleBorder(borderRadius: metrics.selectionBorderRadius),
        labelStyle: typography.bodyMedium!.copyWith(color: scheme.onSurface),
        padding:
            EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.onSurface,
        dividerColor: scheme.surface,
        labelStyle: typography.titleSmall,
        unselectedLabelStyle: typography.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceContainerLow,
        elevation: metrics.subtleElevation,
        textStyle: typography.bodyMedium,
        shape:
            RoundedRectangleBorder(borderRadius: metrics.controlBorderRadius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            typography.bodyMedium!.copyWith(color: scheme.onInverseSurface),
        shape: controlShape,
      ),
    );
  }
}

extension SpacingX on BuildContext {
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
