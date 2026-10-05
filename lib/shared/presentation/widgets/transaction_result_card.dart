import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

/// A transaction result whose text and amount are prepared by its caller.
class TransactionResultCard extends StatelessWidget {
  const TransactionResultCard({
    super.key,
    required this.title,
    required this.metadata,
    required this.date,
    required this.amount,
    required this.amountColor,
    required this.onTap,
    this.badges = const [],
  });

  final String title;
  final String metadata;
  final String date;
  final String amount;
  final Color amountColor;
  final VoidCallback onTap;
  final List<Widget> badges;

  @override
  Widget build(BuildContext context) => AppCard.group(
        child: ListTile(
          onTap: onTap,
          title: Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge),
          subtitle: badges.isEmpty
              ? Text('$metadata\n$date', style: AppTypography.meta(context))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metadata, style: AppTypography.meta(context)),
                    Wrap(
                      spacing: context.spacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(date, style: AppTypography.meta(context)),
                        ...badges
                      ],
                    ),
                  ],
                ),
          isThreeLine: true,
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(amount,
                  style: AppTypography.amount(context)
                      .copyWith(color: amountColor)),
            ),
          ),
        ),
      );
}
