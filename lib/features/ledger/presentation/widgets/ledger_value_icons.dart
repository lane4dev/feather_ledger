import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';

/// A category's colour and icon at the size the form's value column uses.
class LedgerCategoryValueIcon extends StatelessWidget {
  const LedgerCategoryValueIcon({
    super.key,
    required this.iconKey,
    required this.color,
  });

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          color.withValues(alpha: 0.16),
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
      child: CategoryIcon(iconKey: iconKey, size: 14, color: color),
    );
  }
}

/// An account's type icon, matching the account picker's language.
class LedgerAccountValueIcon extends StatelessWidget {
  const LedgerAccountValueIcon({super.key, required this.type});

  final AccountType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.secondaryContainer,
      ),
      child: Icon(type.icon, size: 14, color: scheme.onSecondaryContainer),
    );
  }
}
