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
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      AccountType.cash => l10n.accountTypeCash,
      AccountType.bank => l10n.accountTypeBank,
      AccountType.credit => l10n.accountTypeCredit,
      AccountType.other => l10n.accountTypeOther,
    };
  }
}
