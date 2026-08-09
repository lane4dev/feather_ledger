import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';
import 'transaction_detail_sheet.dart';

enum _DetailAction { edit, delete }

/// The shared recorded-transaction flow for the ledger and search results.
Future<void> showTransactionDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required TransactionTileUiModel transaction,
  String? currencySymbol,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final action = await showAppReceiptSheet<_DetailAction>(
    context: context,
    builder: (sheetContext) => TransactionDetailSheet(
      transaction: transaction,
      currencySymbol: currencySymbol,
      onEdit: () => Navigator.of(sheetContext).pop(_DetailAction.edit),
      onDelete: () async {
        final confirmed = await showDialog<bool>(
          context: sheetContext,
          builder: (dialogContext) => AlertDialog(
            title: Text('${l10n.delete}?'),
            content: Text(l10n.deleteTransactionConfirmation),
            actions: [
              AppButton(
                outlined: true,
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              AppButton(
                destructive: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        if (confirmed == true && sheetContext.mounted) {
          Navigator.of(sheetContext).pop(_DetailAction.delete);
        }
      },
    ),
  );

  // Route and error handling belong to the originating page. The sheet's
  // context is disposed after dismissal and may use a different navigator.
  if (!context.mounted) return;
  switch (action) {
    case _DetailAction.edit:
      await context.push<void>('/ledger/edit', extra: transaction);
    case _DetailAction.delete:
      final result = await ref
          .read(ledgerViewModelProvider.notifier)
          .deleteTransaction(transaction.id);
      if (!context.mounted) return;
      if (result case Failure(:final code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(code.message(l10n))),
        );
      }
    case null:
      break;
  }
}
