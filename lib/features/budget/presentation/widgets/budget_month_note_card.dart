import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

import '../../domain/commands/save_review_note_command.dart';
import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_review_ui_mapper.dart';
import '../view_model/budget_view_model.dart';

/// Month-level review note surface on the L2 review page.
///
/// An empty month shows a dashed prompt; a saved note becomes a handwriting-style
/// excerpt. Both states open the same modal editor, so the page never grows an
/// inline form. The card keeps an optimistic copy of the note it just saved:
/// the summary stream follows a moment later with the persisted write time.
class BudgetMonthNoteCard extends ConsumerStatefulWidget {
  final YearMonth month;
  final String monthLabel;
  final String currencyCode;
  final String? note;
  final String? noteUpdatedDisplay;

  const BudgetMonthNoteCard({
    super.key,
    required this.month,
    required this.monthLabel,
    required this.currencyCode,
    required this.note,
    required this.noteUpdatedDisplay,
  });

  @override
  ConsumerState<BudgetMonthNoteCard> createState() =>
      _BudgetMonthNoteCardState();
}

class _BudgetMonthNoteCardState extends ConsumerState<BudgetMonthNoteCard> {
  static const _radius = 20.0;

  late String? _note;
  late String? _updatedDisplay;

  @override
  void initState() {
    super.initState();
    _note = _normalize(widget.note);
    _updatedDisplay = _note == null ? null : widget.noteUpdatedDisplay;
  }

  @override
  void didUpdateWidget(covariant BudgetMonthNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note != widget.note) {
      _note = _normalize(widget.note);
      _updatedDisplay = _note == null ? null : widget.noteUpdatedDisplay;
    }
  }

  static String? _normalize(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _openEditor() async {
    final saved = await showBudgetMonthNoteSheet(
      context,
      month: widget.month,
      monthLabel: widget.monthLabel,
      currencyCode: widget.currencyCode,
      initialNote: _note,
    );
    if (!mounted || saved == null) return;

    final normalized = _normalize(saved);
    setState(() {
      _note = normalized;
      _updatedDisplay = normalized == null
          ? null
          : formatReviewNoteUpdatedAt(
              ref.read(budgetClockProvider).now(),
              Localizations.localeOf(context).toString(),
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = _note;

    return note == null
        ? _buildEmpty(context, l10n)
        : _buildNote(context, l10n, note);
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(_radius);

    return CustomPaint(
      foregroundPainter: _DashedRoundedBorderPainter(
        color: scheme.outlineVariant,
        borderRadius: radius,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: _openEditor,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.penLine,
                      size: 18,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  SizedBox(width: spacing.sm + spacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.budgetNoteEmptyTitle,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.budgetNoteEmptySubtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 13,
                          color: scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.budgetNoteAdd,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: scheme.onSecondaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNote(
    BuildContext context,
    AppLocalizations l10n,
    String note,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(_radius);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: _openEditor,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.notebookPen,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.budgetMonthNoteLabel,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    IconButton.filledTonal(
                      key: const ValueKey('budget-note-edit'),
                      onPressed: _openEditor,
                      tooltip: l10n.edit,
                      icon: const Icon(LucideIcons.pencil, size: 16),
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(34),
                        maximumSize: const Size.square(34),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: scheme.secondaryContainer,
                        foregroundColor: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          note,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: scheme.onSurface,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_updatedDisplay != null) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    l10n.budgetNoteUpdatedOn(_updatedDisplay!),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the modal month-note editor.
///
/// Returns the saved note text (an empty string when the note was deleted), or
/// null when the sheet was dismissed without saving.
Future<String?> showBudgetMonthNoteSheet(
  BuildContext context, {
  required YearMonth month,
  required String monthLabel,
  required String currencyCode,
  required String? initialNote,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: scheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => BudgetMonthNoteSheet(
      month: month,
      monthLabel: monthLabel,
      currencyCode: currencyCode,
      initialNote: initialNote,
    ),
  );
}

/// Modal editor for the month review note.
///
/// The sheet owns only the draft and the write call; the summary stream and the
/// card own the persisted value (the card keeps an optimistic copy meanwhile).
class BudgetMonthNoteSheet extends ConsumerStatefulWidget {
  final YearMonth month;
  final String monthLabel;
  final String currencyCode;
  final String? initialNote;

  const BudgetMonthNoteSheet({
    super.key,
    required this.month,
    required this.monthLabel,
    required this.currencyCode,
    required this.initialNote,
  });

  @override
  ConsumerState<BudgetMonthNoteSheet> createState() =>
      _BudgetMonthNoteSheetState();
}

class _BudgetMonthNoteSheetState extends ConsumerState<BudgetMonthNoteSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  int get _length => _controller.text.runes.length;

  bool get _overLimit => _length > SaveReviewNoteCommand.maxLength;

  bool get _hasExistingNote =>
      widget.initialNote != null && widget.initialNote!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _persist(String raw) async {
    if (_saving) return false;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);
    final result =
        await ref.read(budgetViewModelProvider.notifier).saveReviewNote(
              currencyCode: widget.currencyCode,
              month: widget.month,
              note: raw,
            );
    if (!mounted) return false;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        return true;
      case Failure(:final code):
        messenger.showSnackBar(SnackBar(content: Text(code.message(l10n))));
        return false;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final raw = _controller.text;

    final saved = await _persist(raw);
    if (!mounted || !saved) return;

    Navigator.of(context).pop(raw.trim());
    messenger.showSnackBar(SnackBar(content: Text(l10n.budgetNoteSaved)));
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final undoLabel = l10n.budgetNoteUndo;
    final previous = widget.initialNote;
    final notifier = ref.read(budgetViewModelProvider.notifier);
    final currencyCode = widget.currencyCode;
    final month = widget.month;

    final deleted = await _persist('');
    if (!mounted || !deleted) return;

    Navigator.of(context).pop('');
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.budgetNoteDeleted),
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () {
            unawaited(
              notifier.saveReviewNote(
                currencyCode: currencyCode,
                month: month,
                note: previous ?? '',
              ),
            );
          },
        ),
      ),
    );
  }

  void _insertPrefix(String prefix) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.isValid &&
            selection.start >= 0 &&
            selection.start <= text.length
        ? selection.start
        : text.length;
    final updated = text.replaceRange(cursor, cursor, prefix);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = context.spacing;
    final scheme = Theme.of(context).colorScheme;
    final length = _length;
    final canSave = !_saving && !_overLimit;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSheetHandle(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.budgetMonthNoteLabel,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.sm,
                          vertical: spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        constraints: const BoxConstraints(maxWidth: 128),
                        child: Text(
                          widget.monthLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                      if (_hasExistingNote) ...[
                        SizedBox(width: spacing.xs),
                        IconButton(
                          key: const ValueKey('budget-note-delete'),
                          onPressed: _saving ? null : _delete,
                          tooltip: l10n.delete,
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          color: scheme.onSurfaceVariant,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The inline field already contributes its 12dp row
                        // inset vertically; the 2dp container padding makes
                        // the visual inset 14dp on every side.
                        AppTextField(
                          key: const ValueKey('budget-note-field'),
                          controller: _controller,
                          variant: AppFieldVariant.inline,
                          minLines: 4,
                          maxLines: 8,
                          autofocus: true,
                          hintText: l10n.budgetNotePlaceholder,
                          textInputAction: TextInputAction.newline,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    height: 1.55,
                                  ),
                          onChanged: (_) => setState(() {}),
                        ),
                        if (length >= 400)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                l10n.budgetNoteCharCount(length),
                                key: const ValueKey('budget-note-counter'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: _overLimit
                                          ? scheme.error
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_controller.text.isEmpty) ...[
                    SizedBox(height: spacing.sm),
                    Wrap(
                      spacing: spacing.xs,
                      runSpacing: spacing.xs,
                      children: [
                        _QuickNoteChip(
                          label: l10n.budgetNoteQuickLargeExpense,
                          onPressed: () => _insertPrefix(
                            l10n.budgetNoteQuickLargeExpensePrefix,
                          ),
                        ),
                        _QuickNoteChip(
                          label: l10n.budgetNoteQuickNextMonth,
                          onPressed: () => _insertPrefix(
                            l10n.budgetNoteQuickNextMonthPrefix,
                          ),
                        ),
                        _QuickNoteChip(
                          label: l10n.budgetNoteQuickTakeaway,
                          onPressed: () => _insertPrefix(
                            l10n.budgetNoteQuickTakeawayPrefix,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              spacing.md,
              spacing.md,
              spacing.md,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: spacing.sm,
              runSpacing: spacing.xs,
              children: [
                AppButton.text(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                AppButton(
                  key: const ValueKey('budget-note-save'),
                  onPressed: canSave ? _save : null,
                  child: Text(l10n.budgetSaveNote),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNoteChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickNoteChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
      backgroundColor: scheme.surfaceContainerLow,
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = (Offset.zero & size).deflate(paint.strokeWidth / 2);
    final path = Path()..addRRect(borderRadius.toRRect(rect));
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 8) {
        canvas.drawPath(
          metric.extractPath(start, (start + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderRadius != borderRadius;
}
