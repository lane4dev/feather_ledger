import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

/// The amount field.
///
/// Controlled from outside: it holds no value of its own. It renders whatever
/// the caller's [controller] holds and reports the raw text of every
/// keystroke; the amount itself lives in the form's view model.
///
/// The conversions between text and minor units deliberately stay out of here.
/// A field that re-formatted its own text as you typed would turn `12.` into
/// `12.00` mid-keystroke and slam the caret to the end, so the round trip
/// happens once on each side instead — format when seeding the controller,
/// parse when the value is used. Between those two moments the text only ever
/// travels user → view model, never back through a formatter.
class LedgerAmountInput extends StatelessWidget {
  final TextEditingController controller;

  /// The raw text, on every change. Not minor units — see the class doc.
  /// Omitted by a caller that only reads [controller] when it saves.
  final ValueChanged<String>? onChanged;

  final TransactionKind type;
  final bool autofocus;
  final String currencySymbol;

  const LedgerAmountInput({
    super.key,
    required this.controller,
    this.onChanged,
    required this.type,
    this.autofocus = false,
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
      TransactionKind.transfer ||
      TransactionKind.openingBalance ||
      TransactionKind.balanceAdjustment =>
        colorScheme.onSurface,
    };

    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // So the symbol sits on the digits' baseline rather than on whatever
        // the decoration's box centres to.
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // The symbol is the unit, not part of the number, so it is drawn in
          // the secondary colour — and it is drawn, always. It cannot be
          // `InputDecoration.prefixText`: the framework fades a prefix
          // completely out unless the field is focused or non-empty
          // (`_AffixText` animates its opacity on the decoration's
          // "label should withdraw" state), so on a *new* entry — empty, and
          // not yet tapped — the symbol was simply absent.
          Text(
            '$currencySymbol ',
            style: theme.textTheme.displayMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: TextFormField(
              controller: controller,
              autofocus: autofocus,
              decoration: InputDecoration(
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  return (text.isEmpty ||
                          RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text))
                      ? newValue
                      : oldValue;
                }),
              ],
              textInputAction: TextInputAction.next,
              onChanged: onChanged,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.required;
                final p = double.tryParse(value);
                if (p == null || p <= 0) return l10n.invalidAmount;
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
