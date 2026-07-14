import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

extension AccountTypeUi on AccountType {
  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return LucideIcons.banknote;
      case AccountType.bank:
        return LucideIcons.landmark;
      case AccountType.credit:
        return LucideIcons.creditCard;
      case AccountType.other:
        return LucideIcons.wallet;
    }
  }

  String localizedLabel(BuildContext context) {
    // Ideally this maps to AppLocalizations keys
    // For now, retaining the simple logic or mapping if keys exist
    // Checking app_localizations... assuming generic fallback or specific keys
    // based on user request context, I'll leave simple logic but ready for l10n
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      // TODO: Add proper keys to arb files: accountTypeCash, etc.
      // returning capitalized name as placeholder matching previous logic
      final name = this.name;
      return name[0].toUpperCase() + name.substring(1);
    }
    return name;
  }
}
