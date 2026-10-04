import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/core/domain/result/result.dart';

/// Maps a [LedgerErrorCode] to its localized user-presentable message
/// (spec 003, US4/T036) — the presentation edge's single failure-rendering
/// point.
///
/// This switch is deliberately **exhaustive with no `_` arm**: adding a
/// [LedgerErrorCode] without its message is then a compile error, rather than
/// a silent fallback that shows the user a raw enum name. It previously had
/// such an arm, and `currencyMismatch`, `sameAccountTransfer` and
/// `unknownEvent` all shipped through it unnoticed (spec 004, FR-027) —
/// `unknownEvent` on *every* unexpected exception, since `guard` assigns it.
/// `ledger_error_localizer_test.dart` keeps the guard on the other side.
extension LedgerErrorLocalizer on LedgerErrorCode {
  String message(AppLocalizations l10n) => switch (this) {
        LedgerErrorCode.accountNotFound => l10n.errorAccountNotFound,
        LedgerErrorCode.accountArchived => l10n.errorAccountArchived,
        LedgerErrorCode.accountHasReferences => l10n.errorAccountHasReferences,
        LedgerErrorCode.accountHasActiveSchedules =>
          l10n.errorAccountHasActiveSchedules,
        LedgerErrorCode.categoryNotFound => l10n.errorCategoryNotFound,
        LedgerErrorCode.categoryArchived => l10n.errorCategoryArchived,
        LedgerErrorCode.categoryTypeMismatch => l10n.errorCategoryTypeMismatch,
        LedgerErrorCode.currencyMismatch => l10n.errorCurrencyMismatch,
        LedgerErrorCode.sameAccountTransfer => l10n.errorSameAccountTransfer,
        LedgerErrorCode.systemCategoryProtected =>
          l10n.errorSystemCategoryProtected,
        LedgerErrorCode.invalidAmount => l10n.invalidAmount,
        LedgerErrorCode.invalidTransfer => l10n.errorInvalidTransfer,
        LedgerErrorCode.invalidTransactionShape =>
          l10n.errorInvalidTransactionShape,
        LedgerErrorCode.transactionNotFound => l10n.errorTransactionNotFound,
        LedgerErrorCode.transactionAlreadyReversed =>
          l10n.errorTransactionAlreadyReversed,
        LedgerErrorCode.scheduledAlreadyPosted =>
          l10n.errorScheduledAlreadyPosted,
        LedgerErrorCode.scheduledNotSkipped => l10n.errorScheduledNotSkipped,
        LedgerErrorCode.recurringSeriesStopped =>
          l10n.errorRecurringSeriesStopped,
        LedgerErrorCode.scheduledDateTaken => l10n.errorScheduledDateTaken,
        LedgerErrorCode.countLimitTooSmall => l10n.errorCountLimitTooSmall,
        LedgerErrorCode.budgetNoteTooLong => l10n.errorBudgetNoteTooLong,
        LedgerErrorCode.unknownEvent => l10n.errorUnknownEvent,
      };
}
