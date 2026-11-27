import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/feather_divider.dart';

/// One grouped surface inside a transaction-like form.
///
/// Rows are separated by the same hairline everywhere so that the add, edit
/// and pending-bill forms read as one page with different fields rather than
/// three layouts that happen to share widgets.
class LedgerFormCard extends StatelessWidget {
  const LedgerFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard.day(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              FeatherDivider(
                indent: context.spacing.md,
                endIndent: context.spacing.md,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The amount and an optional mode control live on one surface: they are two
/// parts of the same decision, and the card gives the number a quiet stage.
///
/// [footer] is a read-only counterpart to the add form's mode selector (the
/// pending-bill form knows its mode and cannot change it).
class LedgerAmountCard extends StatelessWidget {
  const LedgerAmountCard({
    super.key,
    required this.amount,
    this.footer,
  });

  final Widget amount;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Center(child: amount),
          if (footer != null) ...[
            SizedBox(height: context.spacing.md),
            Center(child: footer),
          ],
        ],
      ),
    );
  }
}
