import 'package:flutter/foundation.dart';

/// The current result of one scheduled bill within an automatic-posting
/// batch (spec 006, US48/53/54). A member always ends in exactly one of the
/// four terminal results; [pending] is the transient claim state between
/// batch creation and the bill being settled.
enum AutomaticPostingMemberResult {
  /// Claimed by the batch but not yet settled (still processing, or the
  /// process was interrupted before a result could be recorded).
  pending,

  /// Posted automatically by the catch-up.
  succeeded,

  /// Posting threw — the bill stays in its original month and is retried on
  /// a later run (or handled by the user).
  failed,

  /// The user posted, skipped or deleted the bill themselves.
  userHandled,

  /// The bill was latched permanent-manual (autoPostEligible false).
  manual,
}

/// Persisted automatic-posting progress (spec 006, US46–48).
///
/// A batch is created once per catch-up run with a fixed [cutoff]: bills
/// that come due *after* [cutoff] are never part of this batch — they wait
/// for the next startup. Members are claimed idempotently by scheduled id,
/// so a bill interrupted mid-run is resumed within its original batch and
/// never re-claimed by a later batch (no duplicates).
@immutable
class AutomaticPostingBatch {
  final String id;
  final DateTime createdAt;
  final DateTime cutoff;

  const AutomaticPostingBatch({
    required this.id,
    required this.createdAt,
    required this.cutoff,
  });
}

/// One bill's membership in a batch and its current result.
@immutable
class AutomaticPostingBatchMember {
  final String batchId;
  final String scheduledId;
  final AutomaticPostingMemberResult result;

  const AutomaticPostingBatchMember({
    required this.batchId,
    required this.scheduledId,
    required this.result,
  });
}

AutomaticPostingMemberResult decodeAutomaticPostingMemberResult(String value) {
  return AutomaticPostingMemberResult.values.firstWhere(
    (r) => r.name == value,
    orElse: () => AutomaticPostingMemberResult.pending,
  );
}
