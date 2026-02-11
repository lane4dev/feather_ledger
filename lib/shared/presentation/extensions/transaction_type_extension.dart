import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';

extension TransactionTypeUi on TransactionType {
  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      TransactionType.income => l10n.income,
      TransactionType.expense => l10n.expense,
    };
  }

  Color get color {
    // Standardizing colors for types
    // Using hardcoded Material colors for now, but should ideally come from Theme/Tokens
    return this == TransactionType.income
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE57373);
  }

  String get sign {
    return this == TransactionType.income ? '+' : '-';
  }
}
