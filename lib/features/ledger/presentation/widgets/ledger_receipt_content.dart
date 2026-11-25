import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_badge.dart';
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
      Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Stack(alignment: Alignment.topRight, children: [
            Padding(
              padding: EdgeInsets.only(
                top: status == null ? 0 : context.spacing.sm,
                right: status == null ? 0 : context.spacing.xl,
              ),
              child: Text(
                transaction.formattedAmount(currencySymbol),
                style: AppTypography.amountInput(context)
                    .copyWith(color: amountColor),
                textAlign: TextAlign.center,
              ),
            ),
            if (status != null) AppBadge(label: status!),
          ]),
        ),
      ),
      if (transaction.series case final series?) ...[
        SizedBox(height: context.spacing.sm),
        Center(child: RecurringModeLabel(mode: series.mode)),
      ],
      SizedBox(height: context.spacing.md),
      if (transaction.category != null || transaction.type.isBalancePurpose)
        _CategoryHeading(
            name: transaction.category?.name ??
                _purposeName(l10n, transaction.type),
            iconKey: transaction.category?.iconKey,
            colorInt: transaction.category?.colorInt),
      SizedBox(height: context.spacing.lg),
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
      if (transaction.type.isBalancePurpose)
        AppReceiptRow(
            label: l10n.transactionType,
            value: _purposeName(l10n, transaction.type)),
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
    ]);
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

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({
    required this.name,
    this.iconKey,
    this.colorInt,
  });

  final String name;
  final String? iconKey;
  final int? colorInt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = colorInt == null ? null : Color(colorInt!);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconKey != null)
          CircleAvatar(
            radius: context.spacing.lg,
            backgroundColor: categoryColor?.withValues(alpha: 0.16) ??
                theme.colorScheme.surfaceContainerHighest,
            foregroundColor: categoryColor ?? theme.colorScheme.onSurface,
            child: CategoryIcon(iconKey: iconKey!, size: 24),
          ),
        if (iconKey != null) SizedBox(width: context.spacing.md),
        Flexible(
          child: Text(
            name,
            style: theme.textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
