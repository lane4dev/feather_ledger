import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/export/transaction_csv.dart';

part 'transaction_export_service.g.dart';

/// Writes the current search results out as CSV and hands them to the
/// platform's share sheet (spec 004, US3 / FR-019).
///
/// There is no interface here on purpose. The logic is [transactionsToCsv],
/// a pure function with its own tests; what is left is five lines of file
/// write and platform call, which is IO rather than business logic. An
/// abstraction to make `SharePlus` mockable would be a seam with one
/// implementation and no test behind it.
class TransactionExportService {
  final Directory _tempDir;

  TransactionExportService(this._tempDir);

  /// Exports exactly the rows handed in — what the user can see, so what the
  /// file contains matches what they searched for.
  Future<Result<void>> exportCsv(List<TransactionEntity> rows) {
    return guard(() async {
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file =
          File(p.join(_tempDir.path, 'accounted_for_$stamp.csv'));
      await file.writeAsString(transactionsToCsv(rows), flush: true);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
      );
    });
  }
}

@riverpod
Future<TransactionExportService> transactionExportService(Ref ref) async {
  // A temp copy rather than the support directory: share_plus reaches it
  // through the platform's file provider, and the user's own backup lives
  // elsewhere.
  return TransactionExportService(await getTemporaryDirectory());
}
