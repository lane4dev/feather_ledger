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
    required this.incomeContainer,
    required this.onIncomeContainer,
    required this.expenseContainer,
    required this.onExpenseContainer,
  });

  final Color income;
  final Color expense;
  final Color frequency;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expenseContainer;
  final Color onExpenseContainer;

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? frequency,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expenseContainer,
    Color? onExpenseContainer,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      frequency: frequency ?? this.frequency,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
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
      incomeContainer:
          Color.lerp(incomeContainer, other.incomeContainer, t) ??
              incomeContainer,
      onIncomeContainer:
          Color.lerp(onIncomeContainer, other.onIncomeContainer, t) ??
              onIncomeContainer,
      expenseContainer:
          Color.lerp(expenseContainer, other.expenseContainer, t) ??
              expenseContainer,
      onExpenseContainer:
          Color.lerp(onExpenseContainer, other.onExpenseContainer, t) ??
              onExpenseContainer,
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
    incomeContainer: Color(0xFFDAEDDF),
    onIncomeContainer: Color(0xFF25392E),
    expenseContainer: Color(0xFFF9E5DF),
    onExpenseContainer: Color(0xFF572D22),
  );
  static const _semanticsDark = AppSemanticColors(
    income: Color(0xFF81C995),
    expense: Color(0xFFF2B8B5),
    frequency: Color(0xFFB6AEFF),
    incomeContainer: Color(0xFF1D3A2B),
    onIncomeContainer: Color(0xFFC2EAD0),
    expenseContainer: Color(0xFF4B2521),
    onExpenseContainer: Color(0xFFFFDBD7),
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

  static final lightTheme = buildLight();
  static final darkTheme = buildDark();

  static ThemeData buildLight([ColorScheme? dynamicScheme]) =>
      _build(Brightness.light, dynamicScheme: dynamicScheme);

  static ThemeData buildDark([ColorScheme? dynamicScheme]) =>
      _build(Brightness.dark, dynamicScheme: dynamicScheme);

  static ThemeData _build(
    Brightness brightness, {
    ColorScheme? dynamicScheme,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = dynamicScheme == null
        ? _defaultScheme(brightness)
        : _resolveDynamicScheme(dynamicScheme, brightness);
    final semantics = dynamicScheme == null
        ? (dark ? _semanticsDark : _semanticsLight)
        : _resolveDynamicSemantics(scheme, brightness);
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
        semantics,
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
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: scheme.surfaceContainer,
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
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
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

  static ColorScheme _defaultScheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF216A58),
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFF8AD6BE) : const Color(0xFF1C6956),
      onPrimary: dark ? const Color(0xFF07382C) : const Color(0xFFFFFFFF),
      primaryContainer:
          dark ? const Color(0xFF1F4E42) : const Color(0xFFC5ECDC),
      onPrimaryContainer:
          dark ? const Color(0xFFA6F2DC) : const Color(0xFF153E33),
      secondary: dark ? const Color(0xFFB3CCC0) : const Color(0xFF4A6358),
      onSecondary: dark ? const Color(0xFF1E352C) : const Color(0xFFFFFFFF),
      secondaryContainer:
          dark ? const Color(0xFF314C42) : const Color(0xFFD6E8DC),
      onSecondaryContainer:
          dark ? const Color(0xFFCFE8DB) : const Color(0xFF263D34),
      tertiary: dark ? const Color(0xFFA6CCE0) : const Color(0xFF3E6373),
      onTertiary: dark ? const Color(0xFF093544) : const Color(0xFFFFFFFF),
      tertiaryContainer:
          dark ? const Color(0xFF254B5C) : const Color(0xFFC2E8FA),
      onTertiaryContainer:
          dark ? const Color(0xFFC2E8FA) : const Color(0xFF001F2A),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: dark ? const Color(0xFF690005) : const Color(0xFFFFFFFF),
      errorContainer:
          dark ? const Color(0xFF93000A) : const Color(0xFFFFDAD6),
      onErrorContainer:
          dark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: dark ? const Color(0xFF111413) : const Color(0xFFF7FAF7),
      surfaceDim: dark ? const Color(0xFF111413) : const Color(0xFFD7DFD9),
      surfaceBright: dark ? const Color(0xFF373E3B) : const Color(0xFFF7FAF7),
      surfaceContainerLowest:
          dark ? const Color(0xFF0C0F0E) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF191D1B) : const Color(0xFFEFF4EF),
      surfaceContainer:
          dark ? const Color(0xFF1B201E) : const Color(0xFFE6EDE7),
      surfaceContainerHigh:
          dark ? const Color(0xFF222826) : const Color(0xFFDFE6E1),
      surfaceContainerHighest:
          dark ? const Color(0xFF2B322F) : const Color(0xFFD7DFD9),
      onSurface: dark ? const Color(0xFFE1E6E2) : const Color(0xFF191D1B),
      onSurfaceVariant:
          dark ? const Color(0xFFBCC5BF) : const Color(0xFF424B46),
      outline: dark ? const Color(0xFF8A938D) : const Color(0xFF6E7872),
      outlineVariant: dark ? const Color(0xFF3D4541) : const Color(0xFFC4CEC7),
      inverseSurface: dark ? const Color(0xFFE1E6E2) : const Color(0xFF2D322F),
      onInverseSurface:
          dark ? const Color(0xFF191D1B) : const Color(0xFFEEF2EE),
      inversePrimary: dark ? const Color(0xFF1C6956) : const Color(0xFF8AD6BE),
      surfaceTint: dark ? const Color(0xFF111413) : const Color(0xFFF7FAF7),
    );
  }

  static ColorScheme _resolveDynamicScheme(
    ColorScheme dynamicScheme,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final base = dynamicScheme.brightness == brightness
        ? dynamicScheme
        : ColorScheme.fromSeed(
            seedColor: dynamicScheme.primary,
            brightness: brightness,
          );
    final seeded = ColorScheme.fromSeed(
      seedColor: base.primary,
      brightness: brightness,
    );

    final s0 = base.surface.computeLuminance();
    final s1 = base.surfaceContainerLow.computeLuminance();
    final s2 = base.surfaceContainer.computeLuminance();
    final s3 = base.surfaceContainerHigh.computeLuminance();
    final hasValidSurfaces = dark
        ? base.surface != const Color(0xFF000000) &&
            s0 < s1 &&
            s1 < s2 &&
            s2 < s3
        : s0 > s1 && s1 > s2 && s2 > s3;

    var resolved = hasValidSurfaces
        ? base
        : base.copyWith(
            surface: seeded.surface,
            surfaceDim: seeded.surfaceDim,
            surfaceBright: seeded.surfaceBright,
            surfaceContainerLowest: seeded.surfaceContainerLowest,
            surfaceContainerLow: seeded.surfaceContainerLow,
            surfaceContainer: seeded.surfaceContainer,
            surfaceContainerHigh: seeded.surfaceContainerHigh,
            surfaceContainerHighest: seeded.surfaceContainerHighest,
          );

    if (dark) {
      if (resolved.surface == const Color(0xFF000000)) {
        resolved = resolved.copyWith(surface: const Color(0xFF111413));
      }
      if (resolved.onSurface == const Color(0xFFFFFFFF)) {
        resolved = resolved.copyWith(onSurface: seeded.onSurface);
      }
      if (resolved.primary == const Color(0xFFFFFFFF)) {
        resolved = resolved.copyWith(primary: seeded.primary);
      }
    }

    final surfaces = <Color>[
      resolved.surface,
      resolved.surfaceContainerLow,
      resolved.surfaceContainer,
      resolved.surfaceContainerHigh,
    ];

    final primary = _ensureContrast(resolved.primary, surfaces, 3.0);
    final onPrimary = _ensureContrast(resolved.onPrimary, [primary], 4.5);
    final onPrimaryContainer = _ensureContrast(
      resolved.onPrimaryContainer,
      [resolved.primaryContainer],
      4.5,
    );
    final onSecondaryContainer = _ensureContrast(
      resolved.onSecondaryContainer,
      [resolved.secondaryContainer],
      4.5,
    );
    final onErrorContainer = _ensureContrast(
      resolved.onErrorContainer,
      [resolved.errorContainer],
      4.5,
    );
    final onSurface = _ensureContrast(resolved.onSurface, surfaces, 4.5);
    final onSurfaceVariant =
        _ensureContrast(resolved.onSurfaceVariant, surfaces, 4.5);
    final outline = _ensureContrast(resolved.outline, surfaces, 3.0);

    return resolved.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      onPrimaryContainer: onPrimaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      onErrorContainer: onErrorContainer,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      surfaceTint: resolved.surface,
    );
  }

  static AppSemanticColors _resolveDynamicSemantics(
    ColorScheme scheme,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final base = dark ? _semanticsDark : _semanticsLight;
    final primarySurfaces = <Color>[scheme.surface, scheme.surfaceContainerLow];
    final allCardSurfaces = <Color>[
      scheme.surface,
      scheme.surfaceContainerLow,
      scheme.surfaceContainerHigh,
    ];
    final income = _ensureContrast(
      _ensureContrast(base.income, primarySurfaces, 4.5),
      allCardSurfaces,
      dark ? 4.5 : 3.0,
    );
    final expense = _ensureContrast(
      _ensureContrast(base.expense, primarySurfaces, 4.5),
      allCardSurfaces,
      dark ? 4.5 : 3.0,
    );
    final frequency = _ensureContrast(
      _ensureContrast(base.frequency, primarySurfaces, 4.5),
      allCardSurfaces,
      dark ? 4.5 : 3.0,
    );
    final onIncomeContainer = _ensureContrast(
      base.onIncomeContainer,
      [base.incomeContainer],
      4.5,
    );
    final onExpenseContainer = _ensureContrast(
      base.onExpenseContainer,
      [base.expenseContainer],
      4.5,
    );
    return AppSemanticColors(
      income: income,
      expense: expense,
      frequency: frequency,
      incomeContainer: base.incomeContainer,
      onIncomeContainer: onIncomeContainer,
      expenseContainer: base.expenseContainer,
      onExpenseContainer: onExpenseContainer,
    );
  }

  static Color ensureForegroundContrast(
    Color fg,
    Color background, {
    double minRatio = 4.5,
  }) =>
      _ensureContrast(fg, [background], minRatio);

  static double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
  }

  static Color _ensureContrast(
    Color fg,
    List<Color> backgrounds,
    double minRatio,
  ) {
    if (backgrounds.every((bg) => _contrastRatio(fg, bg) >= minRatio)) {
      return fg;
    }
    final hsl = HSLColor.fromColor(fg);
    final avgBgLum = backgrounds
            .map((b) => b.computeLuminance())
            .reduce((a, b) => a + b) /
        backgrounds.length;
    final goLighter = avgBgLum < 0.5;
    for (var step = 1; step <= 40; step++) {
      final t = step / 40.0;
      final targetL = goLighter
          ? hsl.lightness + (0.94 - hsl.lightness) * t
          : hsl.lightness * (1.0 - t * 0.9);
      final candidate =
          hsl.withLightness(targetL.clamp(0.05, 0.94)).toColor();
      if (backgrounds.every((bg) => _contrastRatio(candidate, bg) >= minRatio)) {
        return candidate;
      }
    }
    return goLighter ? const Color(0xFFE6EBE8) : const Color(0xFF151917);
  }
}

extension SpacingX on BuildContext {
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
