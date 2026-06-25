/// The on-disk name of the ledger database, inside the application support
/// directory (spec 004, US4).
///
/// Shared by the database opener and the restore swap. Deliberately its own
/// dependency-free file: if the two ever disagreed, a restore would quietly
/// replace a file that nothing reads, and the user would see it do nothing.
library;

const String kDatabaseFileName = 'db.sqlite';
