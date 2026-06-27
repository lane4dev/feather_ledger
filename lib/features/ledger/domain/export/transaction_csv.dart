import 'package:intl/intl.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

/// Renders transactions as CSV (spec 004, US3 / FR-019).
///
/// A pure function so it can be tested without a file or a platform channel;
/// writing the bytes and sharing them is the caller's job.
///
/// Three conventions worth stating, because a spreadsheet makes them hard to
/// change your mind about later:
///
/// - **`date` is ISO (`yyyy-MM-dd`)**, not a localized date. It sorts, and it
///   parses in every spreadsheet regardless of the reader's locale.
/// - **`kind` is the enum name** (`income` / `expense` / `transfer`), not a
///   translated label. A machine reads this file; a translated column would
///   change meaning with the app's language.
/// - **`amount` is signed for income/expense and unsigned for transfers**,
///   matching the sign the UI shows. A transfer has no direction from the
///   ledger's point of view — `from` and `to` carry that.
/// No currency-symbol parameter: the `currency` column carries the ISO code,
/// which is what a spreadsheet should be keying on.
String transactionsToCsv(List<TransactionEntity> rows) {
  final buffer = StringBuffer()
    // A byte-order mark, so Excel on Windows reads the UTF-8 correctly.
    // Without it, a note in Chinese renders as mojibake, which for a
    // trilingual app is the common case rather than the edge case.
    ..write('﻿')
    ..writeln(_header.join(','));

  for (final row in rows) {
    final isTransfer = row.type == TransactionKind.transfer;
    buffer.writeln([
      DateFormat('yyyy-MM-dd').format(row.date),
      row.type.name,
      _signedAmount(row),
      row.account.currencyCode,
      row.account.name,
      row.toAccount?.name ?? '',
      isTransfer ? '' : row.category.name,
      row.note ?? '',
    ].map(_escapeField).join(','));
  }

  return buffer.toString();
}

const _header = [
  'date',
  'kind',
  'amount',
  'currency',
  'account',
  'toAccount',
  'category',
  'note',
];

/// The entity's `amount` is the *signed* posting impact, so an expense is
/// already negative. A transfer's two legs cancel, and its amount is the
/// positive sum of one leg — signed again here would read as income.
String _signedAmount(TransactionEntity row) {
  if (row.type == TransactionKind.transfer) {
    return formatMinor(row.amount.abs());
  }
  return formatMinor(row.amount);
}

/// RFC 4180: quote a field that contains a comma, a quote, or a line break,
/// and double any quote inside it.
String _escapeField(String value) {
  final needsQuoting = value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  if (!needsQuoting) return value;
  return '"${value.replaceAll('"', '""')}"';
}
