/// The state of a restore-confirmation barrier (spec 006, US58/US63).
///
/// A restore replaces the ledger with a snapshot taken at
/// [RestoreConfirmationBatch.backupExportedAt]. Bills that were not yet due
/// when that snapshot was taken but fell due by the time the snapshot was
/// applied on this device must not be auto-posted: another device may have
/// already recorded them. They wait behind this barrier until the user
/// confirms or rejects them.
enum RestoreConfirmationStatus {
  /// Waiting for the user's decision.
  pending,

  /// The user agreed; the candidates were posted (spec 006, US63).
  confirmed,

  /// The user declined; the candidates were turned manual (spec 006, US63).
  rejected,
}

/// One restore's confirmation window.
///
/// The window is `(backupExportedAt, createdAt]` — strictly after the backup
/// was exported and at or before the moment the snapshot was applied. A bill
/// is a candidate when its scheduled date lands inside that window and it is
/// otherwise eligible for auto-posting.
class RestoreConfirmationBatch {
  final String id;

  /// When the snapshot was applied on this device (the window's end).
  final DateTime createdAt;

  /// When the backup was exported (the window's start, exclusive).
  final DateTime backupExportedAt;

  final RestoreConfirmationStatus status;

  const RestoreConfirmationBatch({
    required this.id,
    required this.createdAt,
    required this.backupExportedAt,
    this.status = RestoreConfirmationStatus.pending,
  });

  /// Whether [moment] falls inside this batch's confirmation window.
  bool contains(DateTime moment) =>
      moment.isAfter(backupExportedAt) && !moment.isAfter(createdAt);
}
