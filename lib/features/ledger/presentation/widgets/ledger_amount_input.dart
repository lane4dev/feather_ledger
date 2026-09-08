import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

class LedgerAmountInput extends StatelessWidget {
  final int? initialMinorUnits;
  final TransactionKind type;
  final bool autofocus;

  /// Receives the parsed amount in int minor units.
  final FormFieldSetter<int> onSaved;
  final String currencySymbol;

  const LedgerAmountInput({
    super.key,
    this.initialMinorUnits,
    required this.type,
    this.autofocus = false,
    required this.onSaved,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final typeColor = type == TransactionKind.income
        ? context.colors.income
        : context.colors.expense;

    return IntrinsicWidth(
      child: TextFormField(
        autofocus: autofocus,
        initialValue: initialMinorUnits == null
            ? null
            : formatMinor(initialMinorUnits!),
        decoration: InputDecoration(
          prefixText: '$currencySymbol ',
          prefixStyle: theme.textTheme.displayMedium?.copyWith(
            color: typeColor,
            fontWeight: FontWeight.bold,
          ),
          hintText: '0.00',
          hintStyle: theme.textTheme.displayMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: theme.textTheme.displayMedium?.copyWith(
          color: typeColor,
          fontWeight: FontWeight.bold,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;
            return (text.isEmpty || RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text))
                ? newValue
                : oldValue;
          }),
        ],
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) return l10n.required;
          final p = double.tryParse(value);
          if (p == null || p <= 0) return l10n.invalidAmount;
          return null;
        },
        onSaved: (value) => onSaved(parseMinor(value!)),
      ),
    );
  }
}
