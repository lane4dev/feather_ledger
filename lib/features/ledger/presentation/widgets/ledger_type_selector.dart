import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/database/tables.dart';

class LedgerTypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onSelectionChanged;

  const LedgerTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SegmentedButton<TransactionType>(
        segments: [
          ButtonSegment(
            value: TransactionType.expense,
            label: Text(l10n.expense),
          ),
          ButtonSegment(
            value: TransactionType.income,
            label: Text(l10n.income),
          ),
        ],
        selected: {selectedType},
        onSelectionChanged: (Set<TransactionType> newSelection) {
          onSelectionChanged(newSelection.first);
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: WidgetStateProperty.all(BorderSide(
            color: colorScheme.outlineVariant,
          )),
        ),
      ),
    );
  }
}
