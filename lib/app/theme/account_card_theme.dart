import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';

@immutable
class AccountCardTheme extends ThemeExtension<AccountCardTheme> {
  const AccountCardTheme({
    required this.cash,
    required this.bank,
    required this.credit,
    required this.other,
  });

  static const light = AccountCardTheme(
    cash: Color(0xFF92764F),
    bank: Color(0xFF5C7A93),
    credit: Color(0xFF80708E),
    other: Color(0xFF6B8074),
  );
  static const dark = AccountCardTheme(
    cash: Color(0xFFC9B48F),
    bank: Color(0xFFA0B9CE),
    credit: Color(0xFFB8AAC7),
    other: Color(0xFFA9BEB0),
  );

  final Color cash;
  final Color bank;
  final Color credit;
  final Color other;

  Color accent(AccountType type, ColorScheme scheme, {bool archived = false}) {
    final color = switch (type) {
      AccountType.cash => cash,
      AccountType.bank => bank,
      AccountType.credit => credit,
      AccountType.other => other,
    };
    return archived ? Color.lerp(scheme.onSurfaceVariant, color, 0.2)! : color;
  }

  @override
  AccountCardTheme copyWith({
    Color? cash,
    Color? bank,
    Color? credit,
    Color? other,
  }) =>
      AccountCardTheme(
        cash: cash ?? this.cash,
        bank: bank ?? this.bank,
        credit: credit ?? this.credit,
        other: other ?? this.other,
      );

  @override
  AccountCardTheme lerp(ThemeExtension<AccountCardTheme>? other, double t) {
    if (other is! AccountCardTheme) return this;
    return AccountCardTheme(
      cash: Color.lerp(cash, other.cash, t)!,
      bank: Color.lerp(bank, other.bank, t)!,
      credit: Color.lerp(credit, other.credit, t)!,
      other: Color.lerp(this.other, other.other, t)!,
    );
  }
}
