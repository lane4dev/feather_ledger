import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

/// The amount field — and the one place in the presentation layer where an
/// amount legitimately crosses between its two forms.
///
/// It is seeded with the decimal text and hands back minor units
/// ([parseMinor] → `Money.fromDouble`), which is the input boundary AGENTS
/// names as the only double bridge. Everywhere else, converting belongs to the
/// mapper or model that feeds the widget, not to the widget.
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

    // A transfer is neither income nor expense, so it takes the neutral
    // onSurface colour rather than being forced into one of them
    // (spec 004, FR-005).
    final typeColor = switch (type) {
      TransactionKind.income => context.colors.income,
      TransactionKind.expense => context.colors.expense,
      TransactionKind.transfer => colorScheme.onSurface,
    };

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
