import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';

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
  }) : assert(widthFactor == null || (widthFactor > 0 && widthFactor <= 1));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final outerRadius = BorderRadius.circular(14);
    final selectedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final selector = SegmentedButton<TransactionKind>(
      segments: [
        for (final kind in kinds)
          ButtonSegment(
            value: kind,
            label: Text(switch (kind) {
              TransactionKind.expense => l10n.expense,
              TransactionKind.income => l10n.income,
              TransactionKind.transfer => l10n.transfer,
              TransactionKind.openingBalance => l10n.initialBalance,
              TransactionKind.balanceAdjustment =>
                l10n.accountBalanceAdjustmentDescription,
            }),
          ),
      ],
      selected: {selectedType},
      onSelectionChanged: (Set<TransactionKind> newSelection) {
        onSelectionChanged(newSelection.first);
      },
      showSelectedIcon: false,
      expandedInsets: widthFactor == null ? null : EdgeInsets.zero,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.secondaryContainer
              : Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant;
        }),
        // The surface behind the whole group, rather than outlines between
        // its children, is what separates this control from the page.
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(selectedShape),
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.bodyLarge,
        ),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm,
          ),
        ),
      ),
    );

    return Center(
      child: widthFactor == null
          ? _WeakSegmentedSurface(
              borderRadius: outerRadius,
              color: colorScheme.surfaceContainerLow,
              child: selector,
            )
          : FractionallySizedBox(
              widthFactor: widthFactor,
              child: _WeakSegmentedSurface(
                borderRadius: outerRadius,
                color: colorScheme.surfaceContainerLow,
                child: selector,
              ),
            ),
    );
  }
}

class _WeakSegmentedSurface extends StatelessWidget {
  const _WeakSegmentedSurface({
    required this.borderRadius,
    required this.color,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.xs / 2),
          child: child,
        ),
      ),
    );
  }
}
