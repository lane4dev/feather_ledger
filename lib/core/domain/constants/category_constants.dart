/// Identity of the two balance-correction categories the ledger used to file
/// its own adjustments under.
///
/// **These are legacy vocabulary, and the IDs are still load-bearing.**
/// Balance purposes have their own transaction kinds now (ADR-003), so nothing
/// writes these categories any more and a fresh install never gets them. But
/// records written before that change are ordinary income/expense events whose
/// postings name one of these IDs, and they are never rewritten — the projector
/// reads the ID back to work out what such a record actually was
/// (`projectedTransactionKind`). Retiring the IDs would turn every historical
/// balance correction into income again.
///
/// The `*Code`s are what the old seeder stamped into `systemCode`, which is
/// still how the projection hides those rows from every picker. Only tests
/// need them now, to build a ledger that looks like an installation that
/// predates the change.
class CategoryConstants {
  static const String reversalExpenseId =
      '00000000-0000-0000-0000-000000000001';
  static const String reversalIncomeId = '00000000-0000-0000-0000-000000000002';

  static const String reversalExpenseCode = 'REVERSAL_EXPENSE';
  static const String reversalIncomeCode = 'REVERSAL_INCOME';
}
