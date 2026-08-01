import 'package:file_selector/file_selector.dart';

import 'package:feather_ledger/core/domain/enums.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/data/transaction_attachment_store.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';
import 'package:feather_ledger/features/ledger/domain/queries/watch_monthly_snapshot_query.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/ledger/domain/services/recurring_service.dart';
import 'package:feather_ledger/features/ledger/domain/value_objects/account_balance.dart';

/// The write boundary, recorded instead of executed.
///
/// These are what a *widget* test installs, because a widget test is asking
/// "what did the form hand to the write path", not "does the ledger agree" —
/// the second question belongs to the real services, and is asked against a
/// real database in `test/unit/features/ledger/domain/` (see
/// `LedgerServiceHarness`). Keeping the two apart is what lets a widget test
/// run without Drift inside `flutter_test`'s fake-async zone.
///
/// Signatures are mirrored from the real services, so drift breaks the build
/// rather than a test at run time. Reads are not modelled: nothing under test
/// reads through these.
class RecordingLedgerService implements LedgerService {
  final List<Map<String, Object?>> addedTransactions = [];
  final List<Map<String, Object?>> updatedTransactions = [];
  final List<Map<String, Object?>> addedTransfers = [];
  final List<Map<String, Object?>> updatedTransfers = [];
  final List<Map<String, Object?>> updatedBalancePurposes = [];

  /// When set, every write fails with it — the one knob the failure paths need.
  LedgerErrorCode? failure;

  Result<void> _fail() => Failure(failure!, 'rejected');

  @override
  Future<Result<void>> addTransaction({
    required String commandId,
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
    List<TransactionAttachment> attachments = const [],
  }) async {
    if (failure != null) return _fail();
    addedTransactions.add({
      'commandId': commandId,
      'amountMinor': amountMinor,
      'type': type,
      'date': date,
      'categoryId': categoryId,
      'accountId': accountId,
      'note': note,
      'attachments': attachments,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> updateTransaction({
    required String commandId,
    required String id,
    required int amountMinor,
    required TransactionKind type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? note,
    List<TransactionAttachment> attachments = const [],
  }) async {
    if (failure != null) return _fail();
    updatedTransactions.add({
      'commandId': commandId,
      'id': id,
      'amountMinor': amountMinor,
      'type': type,
      'date': date,
      'categoryId': categoryId,
      'accountId': accountId,
      'note': note,
      'attachments': attachments,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> addTransfer({
    required String commandId,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
    List<TransactionAttachment> attachments = const [],
  }) async {
    if (failure != null) return _fail();
    addedTransfers.add({
      'commandId': commandId,
      'amountMinor': amountMinor,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'date': date,
      'note': note,
      'attachments': attachments,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> updateTransfer({
    required String commandId,
    required String id,
    required int amountMinor,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
    List<TransactionAttachment> attachments = const [],
  }) async {
    if (failure != null) return _fail();
    updatedTransfers.add({
      'commandId': commandId,
      'id': id,
      'amountMinor': amountMinor,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'date': date,
      'note': note,
      'attachments': attachments,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> updateBalancePurpose({
    required String commandId,
    required String id,
    required int signedAmountMinor,
    required DateTime date,
    required String accountId,
    String? note,
    List<TransactionAttachment> attachments = const [],
  }) async {
    if (failure != null) return _fail();
    updatedBalancePurposes.add({
      'commandId': commandId,
      'id': id,
      'signedAmountMinor': signedAmountMinor,
      'date': date,
      'accountId': accountId,
      'note': note,
      'attachments': attachments,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> deleteTransaction(String id,
          {required String commandId}) async =>
      unitResult;

  @override
  Future<Result<void>> convertScheduledToPosted(String scheduledId,
          {required String commandId}) async =>
      unitResult;

  @override
  Stream<List<TransactionEntity>> watchTransactions(DateTime month) =>
      throw UnimplementedError();

  @override
  Stream<MonthlySnapshotTotals> watchMonthlySnapshot(DateTime month,
          {required String currencyCode}) =>
      throw UnimplementedError();

  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduledTransactions() =>
      throw UnimplementedError();

  @override
  Future<AccountBalance> accountBalance(String accountId) =>
      throw UnimplementedError();
}

/// [RecurringService], recorded the same way.
class RecordingRecurringService implements RecurringService {
  final List<Map<String, Object?>> created = [];

  /// When set, [createSeries] fails with it — how the form's "the entry stands
  /// even though the schedule did not" path is reached.
  LedgerErrorCode? failure;

  @override
  Future<Result<void>> createSeries({
    required RecurringSeriesKind type,
    required int amountMinor,
    required String accountId,
    required String categoryId,
    required String description,
    required String frequency,
    required int interval,
    required DateTime startDate,
    DateTime? endDate,
    bool autoPost = false,
  }) async {
    if (failure != null) return Failure(failure!, 'rejected');
    created.add({
      'type': type,
      'amountMinor': amountMinor,
      'accountId': accountId,
      'categoryId': categoryId,
      'description': description,
      'frequency': frequency,
      'interval': interval,
      'startDate': startDate,
      'endDate': endDate,
      'autoPost': autoPost,
    });
    return unitResult;
  }

  @override
  Future<Result<void>> deleteBill(String scheduledId,
          {required RecurringScope scope}) async =>
      unitResult;

  @override
  Future<Result<void>> updateBill(
    String scheduledId, {
    required RecurringScope scope,
    required int amountMinor,
    required DateTime date,
    required String categoryId,
    required String accountId,
    required String description,
  }) async =>
      unitResult;

  @override
  Future<Result<void>> postInstance(String scheduledId,
          {String? commandId}) async =>
      unitResult;

  @override
  Future<void> materialize() async {}

  @override
  Future<void> catchUpAutoPosted() async {}

  @override
  Stream<List<ScheduledTransactionEntity>> watchScheduled() =>
      throw UnimplementedError();
}

/// Attachment storage, without a filesystem: `importFiles` hands back one
/// attachment per file, and [discarded] records what a rejected save cleaned up.
class RecordingAttachmentStore implements TransactionAttachmentStore {
  final List<List<XFile>> imported = [];
  final List<List<TransactionAttachment>> discarded = [];

  @override
  Future<List<TransactionAttachment>> importFiles(List<XFile> files) async {
    imported.add(files);
    return [
      for (final file in files)
        TransactionAttachment(
          id: file.name,
          fileName: file.name,
          relativePath: 'transaction_attachments/${file.name}',
          byteSize: 1,
        ),
    ];
  }

  @override
  Future<void> discard(List<TransactionAttachment> attachments) async {
    discarded.add(attachments);
  }
}
