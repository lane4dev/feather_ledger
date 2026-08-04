import 'package:flutter/material.dart';

import 'package:feather_ledger/app/design_system/app_card.dart';
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
      padding: EdgeInsets.all(spacing.lg),
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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.iconBackground(entity.type, scheme,
                      archived: entity.archived),
                  borderRadius: BorderRadius.circular(tokens.iconRadius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(spacing.sm + spacing.xs),
                  child: Icon(entity.type.icon,
                      color: tokens.accent(entity.type, scheme,
                          archived: entity.archived)),
                ),
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
                  _AccountStatus(label: l10n.accountExcludedFromTotals),
                if (entity.archived)
                  _AccountStatus(label: l10n.accountArchived),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountStatus extends StatelessWidget {
  const _AccountStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(context.spacing.xs),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.spacing.sm, vertical: context.spacing.xs),
        child: Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ),
    );
  }
}
