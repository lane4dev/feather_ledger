import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:feather_ledger/features/ledger/domain/model/transaction.dart';

part 'transaction_attachment_store.g.dart';

/// Imports user-selected files into app-private storage before their metadata
/// is recorded in a transaction event. Keeping a private copy means an entry
/// does not break when the original picker location disappears.
class TransactionAttachmentStore {
  static const _directoryName = 'transaction_attachments';

  Future<List<TransactionAttachment>> importFiles(List<XFile> files) async {
    if (files.isEmpty) return const [];

    final supportDir = await getApplicationSupportDirectory();
    final directory = Directory(p.join(supportDir.path, _directoryName));
    await directory.create(recursive: true);

    final imported = <TransactionAttachment>[];
    try {
      for (final source in files) {
        final id = const Uuid().v4();
        final bytes = await source.readAsBytes();
        final relativePath = p.join(_directoryName, id);
        await File(p.join(supportDir.path, relativePath))
            .writeAsBytes(bytes, flush: true);
        imported.add(TransactionAttachment(
          id: id,
          fileName: source.name,
          relativePath: relativePath,
          byteSize: bytes.length,
        ));
      }
      return imported;
    } catch (_) {
      await discard(imported);
      rethrow;
    }
  }

  /// Removes files imported for a save that was rejected before an event was
  /// appended. Saved attachments are never removed here: correction events
  /// retain their historical references for the audit trail.
  Future<void> discard(List<TransactionAttachment> attachments) async {
    if (attachments.isEmpty) return;
    final supportDir = await getApplicationSupportDirectory();
    for (final attachment in attachments) {
      final file = File(p.join(supportDir.path, attachment.relativePath));
      if (await file.exists()) await file.delete();
    }
  }
}

@riverpod
TransactionAttachmentStore transactionAttachmentStore(Ref ref) =>
    TransactionAttachmentStore();
