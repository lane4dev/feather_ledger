import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

/// The ledger's empty state, in two flavours.
///
/// [onCreateAccount] is null when the current currency has at least one
/// account: there is money on screen but no transactions, so the empty state
/// points at the + button. When it is non-null the current currency has no
/// account at all, and the empty state is a create-account prompt instead —
/// a transaction cannot be recorded until some account exists in that
/// currency, so the + button alone would lead the user somewhere useless.
class LedgerEmpty extends StatelessWidget {
  const LedgerEmpty({super.key, this.onCreateAccount});

  final VoidCallback? onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAccounts = onCreateAccount == null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            height: 320,
            child: Image.asset(
              'assets/images/empty_placeholder.png',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: context.spacing.md),
          Text(
            hasAccounts
                ? l10n.noTransactionsTitle
                : l10n.noAccountsInCurrencyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            hasAccounts
                ? l10n.noTransactionsHint
                : l10n.noAccountsInCurrencyHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (!hasAccounts) ...[
            SizedBox(height: context.spacing.lg),
            AppButton(
              onPressed: onCreateAccount,
              icon: const Icon(LucideIcons.plus),
              child: Text(l10n.addAccount),
            ),
          ],
        ],
      ),
    );
  }
}
