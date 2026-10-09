import 'package:flutter/material.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_dialog_option.dart';

Future<String?> showAccountCurrencyDialog(
  BuildContext context, {
  required String selected,
  String? allCurrenciesValue,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(l10n.accountCurrency),
      children: [
        if (allCurrenciesValue != null)
          FeatherDialogOption<String>(
            label: l10n.accountAllCurrencies,
            value: allCurrenciesValue,
            groupValue: selected,
            onChanged: (value) => Navigator.pop(dialogContext, value),
          ),
        for (final code in AppCurrencies.supportedCurrencyCodes)
          FeatherDialogOption<String>(
            label: AppCurrencies.getName(code, l10n),
            value: code,
            groupValue: selected,
            onChanged: (value) => Navigator.pop(dialogContext, value),
          ),
      ],
    ),
  );
}
