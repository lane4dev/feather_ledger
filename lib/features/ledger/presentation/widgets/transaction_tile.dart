import 'package:feather_ledger/app/design_system/app_badge.dart';
import 'package:flutter/material.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/transaction_tile_ui_model.dart';
import '../theme/ledger_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionTileUiModel transaction;
  final VoidCallback? onTap;
  final String? currencySymbol;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveCurrencySymbol =
        currencySymbol ?? AppCurrencies.defaultCurrency.symbol;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSkipped = transaction.isSkipped;

    final amountText = transaction.formattedAmount(effectiveCurrencySymbol);
    final amountStyle = LedgerTheme.transactionAmount(context).copyWith(
      decoration: isSkipped ? TextDecoration.lineThrough : null,
      color: isSkipped
          ? theme.colorScheme.onSurfaceVariant
          : switch (transaction.type) {
              TransactionKind.expense => context.colors.expense,
              TransactionKind.income => context.colors.income,
              TransactionKind.transfer ||
              TransactionKind.openingBalance ||
              TransactionKind.balanceAdjustment =>
                theme.colorScheme.onSurface,
            },
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LedgerTheme.rowMinHeight),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: 10.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textColumn = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(l10n),
                    style: LedgerTheme.transactionTitle(context).copyWith(
                      color: isSkipped
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration:
                          isSkipped ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    _subtitle,
                    style: LedgerTheme.transactionMeta(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final amountWidget = Text(
                amountText,
                textAlign: TextAlign.end,
                style: amountStyle,
              );

              final iconGap = context.spacing.sm + context.spacing.xs;
              final stackedAmount = _shouldStackAmount(
                context,
                maxWidth: constraints.maxWidth,
                amountText: amountText,
                amountStyle: amountStyle,
                avatarGap: iconGap,
                leadingGap: context.spacing.md,
              );

              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLeadingIcon(context),
                      SizedBox(width: iconGap),
                      Expanded(child: textColumn),
                      if (!stackedAmount) ...[
                        SizedBox(width: context.spacing.md),
                        amountWidget,
                      ],
                    ],
                  ),
                  if (stackedAmount)
                    Padding(
                      padding: EdgeInsets.only(
                        left: LedgerTheme.categoryAvatarSize + iconGap,
                        top: context.spacing.xs,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: amountWidget,
                      ),
                    ),
                  if (transaction.isPending)
                    Padding(
                      padding: EdgeInsets.only(
                        left: LedgerTheme.categoryAvatarSize + iconGap,
                        top: context.spacing.xs,
                      ),
                      child: Wrap(
                        spacing: context.spacing.xs,
                        runSpacing: context.spacing.xs,
                        children: [
                          _statusBadge(l10n),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static bool _shouldStackAmount(
    BuildContext context, {
    required double maxWidth,
    required String amountText,
    required TextStyle amountStyle,
    required double avatarGap,
    required double leadingGap,
  }) {
    if (!maxWidth.isFinite) return false;
    final painter = TextPainter(
      text: TextSpan(text: amountText, style: amountStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final amountWidth = painter.width;
    painter.dispose();

    const minTextColumnWidth = 72.0;
    final neededForInline = LedgerTheme.categoryAvatarSize +
        avatarGap +
        minTextColumnWidth +
        leadingGap +
        amountWidth;
    return neededForInline > maxWidth;
  }

  Widget _buildLeadingIcon(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardSurface = scheme.surfaceContainerLow;
    final category = transaction.category;

    final Color bgColor;
    final Color fgColor;

    if (transaction.isSkipped) {
      bgColor = scheme.surfaceContainerHigh;
      fgColor = scheme.onSurfaceVariant;
    } else if (category != null) {
      final rawColor = Color(category.colorInt);
      final isDark = theme.brightness == Brightness.dark;
      bgColor = Color.lerp(cardSurface, rawColor, isDark ? 0.28 : 0.16)!;
      fgColor = AppTheme.ensureForegroundContrast(rawColor, bgColor);
    } else {
      bgColor = scheme.surfaceContainerHigh;
      fgColor = scheme.onSurfaceVariant;
    }

    final Widget icon;
    if (category != null) {
      icon = CategoryIcon(
        iconKey: category.iconKey,
        size: 20.0,
        color: fgColor,
      );
    } else {
      final iconData = switch (transaction.type) {
        TransactionKind.transfer => LucideIcons.arrowLeftRight,
        TransactionKind.openingBalance => LucideIcons.wallet,
        TransactionKind.balanceAdjustment => LucideIcons.slidersHorizontal,
        TransactionKind.income || TransactionKind.expense => LucideIcons.tag,
      };
      icon = Icon(iconData, size: 20.0, color: fgColor);
    }

    return Container(
      width: LedgerTheme.categoryAvatarSize,
      height: LedgerTheme.categoryAvatarSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }

  /// The scheduled status tag (`待入账` / `已跳过` / `自动入账失败`).
  Widget _statusBadge(AppLocalizations l10n) {
    if (transaction.isSkipped) {
      return AppBadge(
        label: l10n.skippedBill,
        icon: LucideIcons.circlePause,
      );
    }
    if (transaction.isFailed) {
      return AppBadge.error(
        label: l10n.failedBill,
        icon: LucideIcons.triangleAlert,
      );
    }
    return AppBadge.outlined(
      label: l10n.pendingBill,
      icon: LucideIcons.clock,
    );
  }

  String _title(AppLocalizations l10n) {
    final hasNote = transaction.note != null && transaction.note!.isNotEmpty;
    if (hasNote) return transaction.note!;
    return switch (transaction.type) {
      TransactionKind.transfer => l10n.transfer,
      TransactionKind.openingBalance => l10n.initialBalance,
      TransactionKind.balanceAdjustment => l10n.accountBalanceAdjustmentDescription,
      TransactionKind.income => transaction.category?.name ?? l10n.income,
      TransactionKind.expense => transaction.category?.name ?? l10n.expense,
    };
  }

  String get _subtitle {
    if (transaction.type == TransactionKind.transfer &&
        transaction.toAccount != null) {
      return '${transaction.account.name} → ${transaction.toAccount!.name}';
    }
    return transaction.account.name;
  }
}
