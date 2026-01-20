import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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
  });

  final Color income;
  final Color expense;

  @override
  AppSemanticColors copyWith({
    Color? income,
    Color? expense,
  }) {
    return AppSemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
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
    );
  }
}

class AppTheme {
  static const spacing = AppSpacing(
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
  );

  static const _semanticsLight = AppSemanticColors(
    income: Colors.green,
    expense: Color(0xFFBA1A1A), // M3 Error default
  );

  static const _semanticsDark = AppSemanticColors(
    income: Color(0xFF81C995), // M3 Green equivalent for dark
    expense: Color(0xFFFFB4AB), // M3 Error Container / Error default for dark
  );

  static const textTheme = TextTheme(
    displayLarge: TextStyle(
        fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleSmall: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    textTheme: textTheme,
    extensions: const <ThemeExtension<dynamic>>[
      spacing,
      _semanticsLight,
    ],
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    textTheme: textTheme,
    extensions: const <ThemeExtension<dynamic>>[
      spacing,
      _semanticsDark,
    ],
  );
}

extension SpacingX on BuildContext {
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get colors => Theme.of(this).extension<AppSemanticColors>()!;
}
