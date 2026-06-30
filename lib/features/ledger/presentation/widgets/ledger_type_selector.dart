import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';

class LedgerTypeSelector extends StatelessWidget {
  final TransactionKind selectedType;
  final ValueChanged<TransactionKind> onSelectionChanged;

  /// Which kinds to offer, in order. Defaults to all three — a recurring
  /// series has one account, so its form passes income and expense only
  /// (ADR-0002) rather than showing a transfer the series cannot be.
  final List<TransactionKind> kinds;

  const LedgerTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelectionChanged,
    this.kinds = const [
      TransactionKind.expense,
      TransactionKind.income,
      TransactionKind.transfer,
    ],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SegmentedButton<TransactionKind>(
        segments: [
          for (final kind in kinds)
            ButtonSegment(
              value: kind,
              label: Text(switch (kind) {
                TransactionKind.expense => l10n.expense,
                TransactionKind.income => l10n.income,
                TransactionKind.transfer => l10n.transfer,
              }),
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
