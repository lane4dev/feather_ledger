import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_segmented_control.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

class LedgerTypeSelector extends StatelessWidget {
  final TransactionKind selectedType;
  final ValueChanged<TransactionKind> onSelectionChanged;

  /// Which kinds to offer, in order. Defaults to all three, income first —
  /// the order money arrives, then leaves, then moves. That order is not the
  /// default *selection*: a new entry is still an expense, which is what the
  /// FAB is for. A recurring series has one account, so its form would pass
  /// income and expense only (ADR-0002) rather than offer a transfer the
  /// series cannot be.
  final List<TransactionKind> kinds;

  /// A proportion of the available content width to occupy. Supplying this
  /// makes the segments fill that width instead of sizing to their labels.
  final double? widthFactor;

  /// Uses a flat tonal selection rather than the raised iOS-style pill.
  final bool flat;

  /// Draws the control in its disabled state. Used where the kind is fixed
  /// (a pending bill) but should still read as the same field as the form
  /// that created it.
  final bool enabled;

  const LedgerTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelectionChanged,
    this.kinds = const [
      TransactionKind.income,
      TransactionKind.expense,
      TransactionKind.transfer,
    ],
    this.widthFactor,
    this.flat = false,
    this.enabled = true,
  }) : assert(widthFactor == null || (widthFactor > 0 && widthFactor <= 1));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tint = switch (selectedType) {
      TransactionKind.income => context.colors.income,
      TransactionKind.expense => context.colors.expense,
      _ => scheme.primary,
    };
    return AppSegmentedControl<TransactionKind>(
      flat: flat,
      selectionColor: flat
          ? Color.alphaBlend(
              tint.withValues(alpha: 0.16), scheme.surfaceContainerHighest)
          : null,
      segments: [
        for (final kind in kinds)
          ButtonSegment(
              value: kind,
              enabled: enabled,
              label: Text(switch (kind) {
                TransactionKind.expense => l10n.expense,
                TransactionKind.income => l10n.income,
                TransactionKind.transfer => l10n.transfer,
                TransactionKind.openingBalance => l10n.initialBalance,
                TransactionKind.balanceAdjustment =>
                  l10n.accountBalanceAdjustmentDescription,
              })),
      ],
      selected: selectedType,
      onSelected: onSelectionChanged,
      widthFactor: widthFactor,
    );
  }
}
