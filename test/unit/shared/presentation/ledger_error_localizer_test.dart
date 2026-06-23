import 'package:flutter_test/flutter_test.dart';

import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../../../support/fakes/fake_app_localizations.dart';

/// Guard for the closed set (spec 004, FR-027 / SC-003).
///
/// [LedgerErrorLocalizer.message] has a `_` arm that renders
/// `errorPrefix(name)` — i.e. the raw enum name shown to a user. It exists so
/// a new code still compiles, which is exactly why nothing else catches a
/// missing case: `currencyMismatch` and `sameAccountTransfer` shipped without
/// one and stayed invisible until the transfer form made them reachable.
void main() {
  final l10n = FakeAppLocalizations();

  test('every LedgerErrorCode has a dedicated localized message', () {
    for (final code in LedgerErrorCode.values) {
      final message = code.message(l10n);

      expect(
        message,
        isNotEmpty,
        reason: '${code.name} renders an empty message',
      );
      expect(
        message,
        isNot(equals(l10n.errorPrefix(code.name))),
        reason: '${code.name} falls through to the errorPrefix fallback, '
            'which shows the raw enum name to the user. Add a case in '
            'ledger_error_localizer.dart and error<CodeName> to all four ARB '
            'files.',
      );
    }
  });

  test('the two transfer codes reachable from the transfer form are mapped',
      () {
    // Named explicitly so a future refactor of the loop above cannot quietly
    // stop covering the codes this spec added.
    expect(
      LedgerErrorCode.currencyMismatch.message(l10n),
      l10n.errorCurrencyMismatch,
    );
    expect(
      LedgerErrorCode.sameAccountTransfer.message(l10n),
      l10n.errorSameAccountTransfer,
    );
    expect(
      LedgerErrorCode.scheduledAlreadyPosted.message(l10n),
      l10n.errorScheduledAlreadyPosted,
    );
  });
}
