import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/config/app_currencies.dart';
import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';

/// Offers to settle the due auto-post bills that accumulated in
/// [currencyCode] while another currency was active (spec 006, US49): post
/// them all now, or freeze them as manual pending bills the user reviews one
/// by one. Returns true when every due bill was posted, false when they were
/// frozen, and false when there was nothing to settle.
Future<bool> showCurrencyBacklogDialog(
  BuildContext context,
  WidgetRef ref,
  String currencyCode,
) async {
  final backlog =
      await ref.read(recurringServiceProvider).getCurrencyBacklog(currencyCode);
  if (backlog.isEmpty || !context.mounted) return false;

  final l10n = AppLocalizations.of(context)!;
  final currencyName = AppCurrencies.getName(currencyCode, l10n);

  final postAll = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.currencyBacklogTitle(currencyName)),
      content: Text(l10n.currencyBacklogMessage(backlog.length)),
      actions: [
        AppButton.text(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.currencyBacklogKeepPending),
        ),
        AppButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.currencyBacklogPostAll),
        ),
      ],
    ),
  );

  if (postAll == null || !context.mounted) return false;
  await ref
      .read(recurringServiceProvider)
      .settleCurrencyBacklog(currencyCode, postAll: postAll);
  return postAll;
}
