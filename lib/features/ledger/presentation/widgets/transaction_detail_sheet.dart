import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/app/theme/category_tokens.dart';
import 'package:feather_ledger/core/domain/enums.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/queries/get_transaction_history_query.dart';
import '../models/transaction_tile_ui_model.dart';
import '../view_model/ledger_view_model.dart';
import 'ledger_delete_menu.dart';
import 'ledger_sheet_handle.dart';

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
    this.currencySymbol,
  });

  final TransactionTileUiModel transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    // The recorded event supplies the actual clock time for the barcode; the
    // person-facing date remains the transaction's selected ledger date.
    final historyAsync =
        ref.watch(getTransactionHistoryProvider(transaction.id));
    final history =
        historyAsync.asData?.value ?? const <TransactionHistoryEntry>[];
    final recordedAt = _recordedAt(history) ?? transaction.date;
    final receiptNumber = _receiptNumber(transaction.date, recordedAt);

    final currency = ref.watch(displayCurrencySymbolProvider);
    final amountColor = switch (transaction.type) {
      TransactionKind.expense => context.colors.expense,
      TransactionKind.income => context.colors.income,
      TransactionKind.transfer ||
      TransactionKind.openingBalance ||
      TransactionKind.balanceAdjustment =>
        theme.colorScheme.onSurface,
    };
    final tearY = context.spacing.xl * 2.75;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        0,
        context.spacing.md,
        context.spacing.sm,
      ),
      child: PhysicalShape(
        clipper: _ReceiptClipper(
          topRadius: context.spacing.xl,
          notchRadius: context.spacing.sm,
          tearY: tearY,
          scallopRadius: context.spacing.xs,
        ),
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
        elevation: context.spacing.sm,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: tearY,
                child: Column(
                  children: [
                    const LedgerSheetHandle(),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.spacing.lg,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.x),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: l10n.cancel,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(LucideIcons.squarePen),
                              onPressed: onEdit,
                              tooltip: l10n.edit,
                            ),
                            LedgerDeleteMenu(
                              onDelete: () => onDelete?.call(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Perforation(color: theme.colorScheme.outlineVariant),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    context.spacing.xl,
                    context.spacing.xl,
                    context.spacing.xl,
                    context.spacing.xl + context.spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${transaction.displaySign} $currency${transaction.displayAmount}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.spacing.md),
                      if (transaction.category != null ||
                          transaction.type.isBalancePurpose)
                        _CategoryHeading(
                          name: transaction.category?.name ??
                              _purposeName(l10n, transaction.type),
                          iconKey: transaction.category?.iconKey,
                          colorInt: transaction.category?.colorInt,
                        ),
                      SizedBox(height: context.spacing.lg),
                      const _DashedDivider(),
                      _ReceiptRow(
                        label: l10n.date,
                        value: DateFormat.yMMMMEEEEd(locale)
                            .format(transaction.date),
                      ),
                      if (transaction.type.isBalancePurpose)
                        _ReceiptRow(
                          label: l10n.transactionType,
                          value: _purposeName(l10n, transaction.type),
                        ),
                      if (transaction.type == TransactionKind.transfer &&
                          transaction.toAccount != null) ...[
                        _ReceiptRow(
                          label: l10n.transferFrom,
                          value: transaction.account.name,
                        ),
                        _ReceiptRow(
                          label: l10n.transferTo,
                          value: transaction.toAccount!.name,
                        ),
                      ] else
                        _ReceiptRow(
                          label: l10n.account,
                          value: transaction.account.name,
                        ),
                      if (transaction.note case final note?
                          when note.isNotEmpty)
                        _ReceiptRow(label: l10n.note, value: note),
                      if (transaction.attachments.isNotEmpty)
                        _ReceiptRow(
                          label: l10n.attachments,
                          value: transaction.attachments
                              .map((attachment) => attachment.fileName)
                              .join('\n'),
                        ),
                      SizedBox(height: context.spacing.lg),
                      SizedBox(
                        key: const ValueKey('transaction-barcode'),
                        height: 88,
                        child: CustomPaint(
                          painter: _Code128Painter(
                            value: receiptNumber,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: context.spacing.sm),
                      Text(
                        receiptNumber.split('').join(' '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  String _purposeName(AppLocalizations l10n, TransactionKind type) =>
      switch (type) {
        TransactionKind.openingBalance => l10n.initialBalance,
        TransactionKind.balanceAdjustment =>
          l10n.accountBalanceAdjustmentDescription,
        _ => '',
      };
}

class _CategoryHeading extends StatelessWidget {
  const _CategoryHeading({
    required this.name,
    this.iconKey,
    this.colorInt,
  });

  final String name;
  final String? iconKey;
  final int? colorInt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = colorInt == null ? null : Color(colorInt!);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconKey != null)
          CircleAvatar(
            radius: context.spacing.lg,
            backgroundColor: categoryColor?.withValues(alpha: 0.16) ??
                theme.colorScheme.surfaceContainerHighest,
            foregroundColor: categoryColor ?? theme.colorScheme.onSurface,
            child: Icon(CategoryTokens.iconFor(iconKey!), size: 24),
          ),
        if (iconKey != null) SizedBox(width: context.spacing.md),
        Flexible(
          child: Text(
            name,
            style: theme.textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: context.spacing.xl * 2,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const _DashedDivider(),
      ],
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.spacing.xs,
      width: double.infinity,
      child: CustomPaint(
        painter: _DottedLinePainter(
          color: color,
          radius: context.spacing.xs / 2,
          gap: context.spacing.sm,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: Theme.of(context).colorScheme.outlineVariant,
          dash: context.spacing.sm,
          gap: context.spacing.xs,
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({
    required this.color,
    required this.radius,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = radius; x < size.width; x += radius * 2 + gap) {
      canvas.drawCircle(Offset(x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      radius != oldDelegate.radius ||
      gap != oldDelegate.gap;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dash).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color ||
      dash != oldDelegate.dash ||
      gap != oldDelegate.gap;
}

class _ReceiptClipper extends CustomClipper<Path> {
  const _ReceiptClipper({
    required this.topRadius,
    required this.notchRadius,
    required this.tearY,
    required this.scallopRadius,
  });

  final double topRadius;
  final double notchRadius;
  final double tearY;
  final double scallopRadius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(topRadius, 0)
      ..lineTo(size.width - topRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, topRadius)
      ..lineTo(size.width, tearY - notchRadius)
      ..quadraticBezierTo(
        size.width - notchRadius,
        tearY - notchRadius,
        size.width - notchRadius,
        tearY,
      )
      ..quadraticBezierTo(
        size.width - notchRadius,
        tearY + notchRadius,
        size.width,
        tearY + notchRadius,
      )
      ..lineTo(size.width, size.height - scallopRadius * 2);

    var x = size.width;
    while (x > scallopRadius * 2) {
      path
        ..quadraticBezierTo(
          x - scallopRadius,
          size.height - scallopRadius * 2,
          x - scallopRadius,
          size.height - scallopRadius,
        )
        ..quadraticBezierTo(
          x - scallopRadius,
          size.height,
          x - scallopRadius * 2,
          size.height,
        );
      x -= scallopRadius * 2;
    }

    path
      ..lineTo(0, size.height)
      ..lineTo(0, tearY + notchRadius)
      ..quadraticBezierTo(
        notchRadius,
        tearY + notchRadius,
        notchRadius,
        tearY,
      )
      ..quadraticBezierTo(
        notchRadius,
        tearY - notchRadius,
        0,
        tearY - notchRadius,
      )
      ..lineTo(0, topRadius)
      ..quadraticBezierTo(0, 0, topRadius, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_ReceiptClipper oldClipper) =>
      topRadius != oldClipper.topRadius ||
      notchRadius != oldClipper.notchRadius ||
      tearY != oldClipper.tearY ||
      scallopRadius != oldClipper.scallopRadius;
}

/// A scannable Code 128 barcode generated from the transaction date and the
/// time at which its recorded event occurred.
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
