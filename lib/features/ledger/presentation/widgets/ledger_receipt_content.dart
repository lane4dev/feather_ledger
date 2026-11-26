import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/shared/presentation/widgets/category_icon.dart';
import 'package:feather_ledger/core/domain/enums.dart';

import '../models/transaction_tile_ui_model.dart';
import '../../domain/entities/ledger_entities.dart';
import 'ledger_delete_menu.dart';
import 'recurring_mode_label.dart';

class LedgerReceiptToolbar extends StatelessWidget {
  const LedgerReceiptToolbar({
    super.key,
    this.onEdit,
    this.onDelete,
    this.overflowActions,
    this.showEdit = true,
    this.showDelete = true,
  });
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<LedgerOverflowAction>? overflowActions;
  final bool showEdit;
  final bool showDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(children: [
      AppIconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: l10n.cancel),
      const Spacer(),
      if (showEdit)
        AppIconButton(
            icon: const Icon(LucideIcons.squarePen),
            onPressed: onEdit,
            tooltip: l10n.edit),
      if (showDelete)
        LedgerDeleteMenu(
          onDelete: () => onDelete?.call(),
          actions: overflowActions,
        ),
    ]);
  }
}

/// Common facts only. A pending bill never reads a recorded transaction's history.
class LedgerReceiptContent extends StatelessWidget {
  const LedgerReceiptContent(
      {super.key,
      required this.transaction,
      required this.currencySymbol,
      this.status});
  final TransactionTileUiModel transaction;
  final String currencySymbol;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final amountColor = switch (transaction.type) {
      TransactionKind.income => context.colors.income,
      TransactionKind.expense => context.colors.expense,
      _ => Theme.of(context).colorScheme.onSurface,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ReceiptAmount(
        amount: _groupThousands(transaction.formattedAmount(currencySymbol)),
        color: amountColor,
        status: status,
      ),
      if (transaction.series case final series?) ...[
        SizedBox(height: context.spacing.xs),
        Center(child: RecurringModeLabel(mode: series.mode)),
      ],
      if (transaction.category != null ||
          transaction.type.isBalancePurpose) ...[
        SizedBox(height: context.spacing.sm),
        _CategoryHeading(
          name: transaction.category?.name ??
              _purposeName(l10n, transaction.type),
          iconKey: transaction.category?.iconKey,
          colorInt: transaction.category?.colorInt,
          type: transaction.type,
        ),
      ],
      SizedBox(height: context.spacing.md),
      const AppReceiptDivider(),
      AppReceiptRow(
          label: l10n.date,
          value: '${DateFormat.yMMMMd(locale).format(transaction.date)} '
              '${DateFormat.Hm(locale).format(transaction.date)}'),
      if (transaction.series case final series?) ...[
        if (series.mode != RecurringSeriesMode.planned)
          AppReceiptRow(
              label: l10n.repeat,
              value: _recurrenceLabel(series, l10n, locale)),
        if (series.reminderMinutes case final minutes?)
          AppReceiptRow(
              label: l10n.reminder, value: l10n.reminderMinutesValue(minutes)),
      ],
      if (transaction.type == TransactionKind.transfer &&
          transaction.toAccount != null) ...[
        AppReceiptRow(
            label: l10n.transferFrom, value: transaction.account.name),
        AppReceiptRow(
            label: l10n.transferTo, value: transaction.toAccount!.name),
      ] else
        AppReceiptRow(label: l10n.account, value: transaction.account.name),
      if (transaction.note case final note? when note.isNotEmpty)
        AppReceiptRow(label: l10n.note, value: note),
      if (transaction.attachments.isNotEmpty)
        AppReceiptRow(
            label: l10n.attachments,
            value: transaction.attachments
                .map((attachment) => attachment.fileName)
                .join('\n')),
      const AppReceiptDivider(),
    ]);
  }

  /// `12,345.67` for the receipt's hero amount. The list rows keep the plain
  /// formatter; only the paper needs printed grouping.
  String _groupThousands(String amount) {
    final dot = amount.indexOf('.');
    final whole = dot < 0 ? amount : amount.substring(0, dot);
    final fraction = dot < 0 ? '' : amount.substring(dot);
    final grouped = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$grouped$fraction';
  }

  String _recurrenceLabel(RecurringTransactionSeriesEntity series,
      AppLocalizations l10n, String locale) {
    final unit = switch (series.frequency.toUpperCase()) {
      'DAILY' => l10n.frequencyDaily,
      'WEEKLY' => l10n.frequencyWeekly,
      'YEARLY' => l10n.frequencyYearly,
      _ => l10n.frequencyMonthly,
    };
    final parts = <String>['${l10n.repeatEvery} ${series.interval ?? 1} $unit'];
    final byDay = RegExp(r'(?:^|;)BYDAY=([^;]+)')
        .firstMatch(series.rrule ?? '')
        ?.group(1);
    if (byDay != null) {
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final days = byDay
          .split(',')
          .map((code) => codes.indexOf(code))
          .where((day) => day >= 0);
      parts.add(days
          .map((day) => DateFormat.E(locale).format(DateTime(2024, 1, day + 1)))
          .join(', '));
    }
    if (series.endDate case final end?) {
      parts.add('${l10n.repeatUntil} ${DateFormat.yMMMd(locale).format(end)}');
    } else if (series.limit case final count?) {
      parts.add('${l10n.repeatCountPrefix} $count ${l10n.repeatCountSuffix}');
    }
    return parts.join(' · ');
  }

  String _purposeName(AppLocalizations l10n, TransactionKind type) =>
      switch (type) {
        TransactionKind.openingBalance => l10n.initialBalance,
        TransactionKind.balanceAdjustment =>
          l10n.accountBalanceAdjustmentDescription,
        _ => '',
      };
}

class _ReceiptAmount extends StatelessWidget {
  const _ReceiptAmount({
    required this.amount,
    required this.color,
    this.status,
  });

  final String amount;
  final Color color;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final amountText = Text(
      amount,
      textAlign: TextAlign.center,
      style: AppTypography.amountInput(context).copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    if (status == null) {
      return Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: amountText),
      );
    }

    // The reserved mirror keeps the amount on the sheet's centre axis while
    // the badge lives outside the digits, never over them.
    final badge = _ReceiptStatusBadge(label: status!);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: badge,
            ),
            SizedBox(width: context.spacing.xs + 2),
            Padding(
              padding: EdgeInsets.only(top: context.spacing.xs),
              child: amountText,
            ),
            SizedBox(width: context.spacing.xs + 2),
            Padding(
              padding: EdgeInsets.only(top: context.spacing.xs),
              child: badge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptStatusBadge extends StatelessWidget {
  const _ReceiptStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.metrics.compactBadgeHorizontalPadding,
        vertical: context.metrics.compactBadgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.55 : 0.72,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 10.5,
          height: 1.15,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({
    required this.name,
    required this.type,
    this.iconKey,
    this.colorInt,
  });

  final String name;
  final TransactionKind type;
  final String? iconKey;
  final int? colorInt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = colorInt == null ? null : Color(colorInt!);
    final purpose = type.isBalancePurpose;
    final accent = categoryColor ?? theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: purpose
                ? theme.colorScheme.surfaceContainerHighest
                : categoryColor?.withValues(alpha: 0.16) ??
                    theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: purpose
                ? Icon(LucideIcons.slidersHorizontal,
                    size: 18, color: theme.colorScheme.onSurfaceVariant)
                : CategoryIcon(iconKey: iconKey ?? '', size: 18, color: accent),
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Flexible(
          child: Text(
            name,
            style: theme.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
