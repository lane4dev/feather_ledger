import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/design_system/app_receipt_sheet.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';

import '../../domain/queries/get_transaction_history_query.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';
import 'ledger_receipt_content.dart';

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet(
      {super.key,
      required this.transaction,
      this.onEdit,
      this.onDelete,
      this.currencySymbol});
  final TransactionTileUiModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Only a recorded receipt resolves event history for the barcode clock.
    final historyAsync =
        ref.watch(getTransactionHistoryProvider(transaction.id));
    final history =
        historyAsync.asData?.value ?? const <TransactionHistoryEntry>[];
    final recordedAt = _recordedAt(history) ?? transaction.date;
    final receiptNumber = _receiptNumber(transaction.date, recordedAt);
    final currency =
        currencySymbol ?? ref.watch<String>(displayCurrencySymbolProvider);
    return AppReceiptSheet(
      toolbar: LedgerReceiptToolbar(onEdit: onEdit, onDelete: onDelete),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LedgerReceiptContent(
            transaction: transaction, currencySymbol: currency),
        SizedBox(height: context.spacing.md),
        SizedBox(
          key: const ValueKey('transaction-barcode'),
          height: 38,
          child: CustomPaint(
            painter: _Code128Painter(
              value: receiptNumber,
              color: theme.colorScheme.onSurface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.28 : 0.24,
              ),
            ),
          ),
        ),
        SizedBox(height: context.spacing.sm),
        Text(receiptNumber.split('').join(' '),
            style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false),
      ]),
    );
  }

  DateTime? _recordedAt(List<TransactionHistoryEntry> history) {
    for (final entry in history) {
      if (entry.eventType == 'TransactionRecorded') return entry.occurredAt;
    }
    return null;
  }

  String _receiptNumber(DateTime ledgerDate, DateTime recordedAt) =>
      '${DateFormat('yyyyMMdd').format(ledgerDate)}'
      '${DateFormat('HHmmssSSS').format(recordedAt)}';
}

class _Code128Painter extends CustomPainter {
  const _Code128Painter({required this.value, required this.color});

  final String value;
  final Color color;

  static const _patterns = <String>[
    '212222',
    '222122',
    '222221',
    '121223',
    '121322',
    '131222',
    '122213',
    '122312',
    '132212',
    '221213',
    '221312',
    '231212',
    '112232',
    '122132',
    '122231',
    '113222',
    '123122',
    '123221',
    '223211',
    '221132',
    '221231',
    '213212',
    '223112',
    '312131',
    '311222',
    '321122',
    '321221',
    '312212',
    '322112',
    '322211',
    '212123',
    '212321',
    '232121',
    '111323',
    '131123',
    '131321',
    '112313',
    '132113',
    '132311',
    '211313',
    '231113',
    '231311',
    '112133',
    '112331',
    '132131',
    '113123',
    '113321',
    '133121',
    '313121',
    '211331',
    '231131',
    '213113',
    '213311',
    '213131',
    '311123',
    '311321',
    '331121',
    '312113',
    '312311',
    '332111',
    '314111',
    '221411',
    '431111',
    '111224',
    '111422',
    '121124',
    '121421',
    '141122',
    '141221',
    '112214',
    '112412',
    '122114',
    '122411',
    '142112',
    '142211',
    '241211',
    '221114',
    '413111',
    '241112',
    '134111',
    '111242',
    '121142',
    '121241',
    '114212',
    '124112',
    '124211',
    '411212',
    '421112',
    '421211',
    '212141',
    '214121',
    '412121',
    '111143',
    '111341',
    '131141',
    '114113',
    '114311',
    '411113',
    '411311',
    '113141',
    '114131',
    '311141',
    '411131',
    '211412',
    '211214',
    '211232',
    '2331112',
  ];

  List<int> _symbols() {
    final symbols = <int>[104, value.codeUnitAt(0) - 32, 99];
    for (var index = 1; index < value.length; index += 2) {
      symbols.add(int.parse(value.substring(index, index + 2)));
    }
    var checksum = symbols.first;
    for (var index = 1; index < symbols.length; index++) {
      checksum += symbols[index] * index;
    }
    return [...symbols, checksum % 103, 106];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final symbols = _symbols();
    final modules = symbols
        .map((symbol) => _patterns[symbol])
        .expand((pattern) => pattern.split(''))
        .fold<int>(20, (sum, width) => sum + int.parse(width));
    final moduleWidth = size.width / modules;
    final paint = Paint()..color = color;
    var x = moduleWidth * 10;

    for (final symbol in symbols) {
      final pattern = _patterns[symbol];
      for (var index = 0; index < pattern.length; index++) {
        final width = int.parse(pattern[index]) * moduleWidth;
        if (index.isEven) {
          canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
        }
        x += width;
      }
    }
  }

  @override
  bool shouldRepaint(_Code128Painter oldDelegate) =>
      value != oldDelegate.value || color != oldDelegate.color;
}
