import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';

class LedgerTypeSelector extends StatelessWidget {
  final TransactionKind selectedType;
  final ValueChanged<TransactionKind> onSelectionChanged;

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
      child: SegmentedButton<TransactionKind>(
        segments: [
          ButtonSegment(
            value: TransactionKind.expense,
            label: Text(l10n.expense),
          ),
          ButtonSegment(
            value: TransactionKind.income,
            label: Text(l10n.income),
          ),
        ],
        selected: {selectedType},
        onSelectionChanged: (Set<TransactionKind> newSelection) {
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
