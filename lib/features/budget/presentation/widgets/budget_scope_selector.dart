import 'package:flutter/material.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../../domain/value_objects/budget_value_objects.dart';

/// Full-width, flat scope switch shared by the budget sheet and the delete
/// confirmation.
///
/// The design-system [AppSegmentedControl] raises its selection with a shadow.
/// These two surfaces sit directly above a primary button, so a floating
/// selection would read as a second, competing control. Here the selection is
/// painted with a tonal fill only, and the segments stretch edge to edge so
/// the control and the button below it share the same left and right margin.
class BudgetScopeSelector extends StatelessWidget {
  const BudgetScopeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BudgetEditScope value;
  final ValueChanged<BudgetEditScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(context.metrics.controlRadius);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<BudgetEditScope>(
        key: const ValueKey('budget-scope-selector'),
        segments: [
          ButtonSegment(
            value: BudgetEditScope.thisMonthOnly,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l10n.budgetScopeThisMonth),
            ),
          ),
          ButtonSegment(
            value: BudgetEditScope.thisAndFollowing,
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l10n.budgetScopeThisAndFollowing),
            ),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.single),
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? scheme.onSurface.withValues(alpha: 0.06)
                : null,
          ),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius),
          ),
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}
