import 'package:feather_ledger/app/design_system/app_text_field.dart';
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
///
/// **A balance purpose's amount carries its own sign.** Income, expense and
/// transfer say which way the money went through their kind, so a sign in the
/// number would be a second answer to a question already answered. An opening
/// balance or an adjustment has no such kind — the sign *is* the direction —
/// so for those the field takes a `-` (and a `+` clears it again, for a
/// physical keyboard).
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

  /// At most two decimals, and a minus only where the number carries the
  /// direction itself.
  static final _unsignedAmount = RegExp(r'^\d*\.?\d{0,2}$');
  static final _signedAmount = RegExp(r'^-?\d*\.?\d{0,2}$');

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

    // See the class doc: only the two kinds that carry no direction of their
    // own let the number carry one.
    final signed = type.isBalancePurpose;

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
            style: AppTypography.amountInput(context)
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Flexible(
            child: AppTextField(
              controller: controller,
              autofocus: autofocus,
              variant: AppFieldVariant.amount,
              hintText: '0.00',
              style:
                  AppTypography.amountInput(context).copyWith(color: typeColor),
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
                // Without this the keypad has no minus to press, and the
                // formatter below would be waiting for a character the user
                // cannot type.
                signed: signed,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final allowed = signed ? _signedAmount : _unsignedAmount;

                  // A `+` means "positive" — it clears the sign rather than
                  // becoming a character in the number. Only a physical
                  // keyboard sends one; a keypad offers digits and a minus.
                  if (signed && newValue.text.contains('+')) {
                    final text = newValue.text.replaceAll(RegExp(r'[+-]'), '');
                    if (!(text.isEmpty || allowed.hasMatch(text))) {
                      return oldValue;
                    }
                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(
                        offset:
                            newValue.selection.baseOffset.clamp(0, text.length),
                      ),
                    );
                  }

                  // Untouched when it is fine: rebuilding the value here would
                  // collapse a selection and drop the composing region on
                  // every ordinary keystroke.
                  if (newValue.text.isEmpty ||
                      allowed.hasMatch(newValue.text)) {
                    return newValue;
                  }
                  return oldValue;
                }),
              ],
              textInputAction: TextInputAction.next,
              onChanged: onChanged,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n.required;
                final p = double.tryParse(value);
                // Zero is not an amount, whichever way it points.
                if (p == null || p == 0) return l10n.invalidAmount;
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
