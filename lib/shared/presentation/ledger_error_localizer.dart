import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

/// Maps a [LedgerErrorCode] to its localized user-presentable message
/// (spec 003, US4/T036) — the presentation edge's single failure-rendering
/// point.
extension LedgerErrorLocalizer on LedgerErrorCode {
  String message(AppLocalizations l10n) => switch (this) {
        LedgerErrorCode.accountNotFound => l10n.errorAccountNotFound,
        LedgerErrorCode.accountArchived => l10n.errorAccountArchived,
        LedgerErrorCode.categoryNotFound => l10n.errorCategoryNotFound,
        LedgerErrorCode.categoryArchived => l10n.errorCategoryArchived,
        LedgerErrorCode.categoryTypeMismatch =>
          l10n.errorCategoryTypeMismatch,
        LedgerErrorCode.systemCategoryProtected =>
          l10n.errorSystemCategoryProtected,
        LedgerErrorCode.invalidAmount => l10n.invalidAmount,
        LedgerErrorCode.invalidTransfer => l10n.errorInvalidTransfer,
        LedgerErrorCode.transactionNotFound => l10n.errorTransactionNotFound,
        LedgerErrorCode.transactionAlreadyReversed =>
          l10n.errorTransactionAlreadyReversed,
        _ => l10n.errorPrefix(name),
      };
}
