import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/account_card_theme.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

import '../theme/settings_theme.dart';

class AccountTile extends StatelessWidget {
  final AccountUiModel account;
  final VoidCallback? onTap;

  const AccountTile({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entity = account.account;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<AccountCardTheme>()!;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context)!;

    return AppCard.account(
      type: entity.type,
      archived: entity.archived,
      onTap: onTap,
      padding: context.metrics.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entity.name,
                        style: SettingsTheme.accountName(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: spacing.xs),
                    Text(entity.type.localizedLabel(context),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              SizedBox(width: spacing.md),
              AppIconBadge(
                icon: entity.type.icon,
                color: tokens.accent(entity.type, scheme,
                    archived: entity.archived),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Text(l10n.balance,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(account.displayBalance,
                        maxLines: 1,
                        style: SettingsTheme.accountBalance(context)),
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              Icon(LucideIcons.chevronRight,
                  size: spacing.md,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55)),
            ],
          ),
          if (entity.archived || !entity.includeInTotals) ...[
            SizedBox(height: spacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: spacing.sm,
              runSpacing: spacing.xs,
              children: [
                if (!entity.includeInTotals)
                  AppBadge(label: l10n.accountExcludedFromTotals),
                if (entity.archived) AppBadge(label: l10n.accountArchived),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
