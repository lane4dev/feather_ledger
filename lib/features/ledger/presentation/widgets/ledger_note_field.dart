import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../theme/ledger_theme.dart';
import 'ledger_form_row.dart';

class LedgerNoteField extends StatelessWidget {
  const LedgerNoteField(
      {super.key,
      required this.controller,
      required this.labelWidth,
      this.onChanged,
      this.card = false});
  final TextEditingController controller;
  final double labelWidth;
  final ValueChanged<String>? onChanged;

  /// Uses the grouped-card inset instead of the page margin.
  final bool card;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LedgerFormRow(
      card: card,
      icon: LucideIcons.stickyNote,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.metrics.rowInset),
          child: SizedBox(
              width: labelWidth,
              child: Text(l10n.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge)),
        ),
        const SizedBox(width: LedgerTheme.formLabelGap),
        Expanded(
            child: AppTextField(
          controller: controller,
          onChanged: onChanged,
          variant: AppFieldVariant.inline,
          hintText: l10n.noteHint,
          minLines: 1,
          maxLines: 3,
          style: Theme.of(context).textTheme.bodyLarge,
        )),
      ]),
    );
  }
}
