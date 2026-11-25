import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:feather_ledger/app/design_system/app_button.dart';
import 'package:feather_ledger/app/design_system/app_sheet_handle.dart';
import 'package:feather_ledger/app/design_system/app_text_field.dart';
import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:feather_ledger/core/domain/result/result.dart';
import 'package:feather_ledger/features/budget/domain/commands/save_review_note_command.dart';
import 'package:feather_ledger/shared/presentation/ledger_error_localizer.dart';

/// A review-note surface shared by the month page (L2) and the category page
/// (L3).
///
/// The month and category notes answer the same question about different
/// scopes, so they look and behave the same way: a dashed prompt when empty, a
/// handwritten excerpt once saved, and a modal editor for both. The card owns
/// no data — the caller passes the persisted note and receives the saved text
/// back from [showBudgetNoteSheet] for an optimistic update.
class BudgetNoteCard extends StatelessWidget {
  static const _radius = 20.0;

  /// Label in the saved card's header. The empty prompt speaks through
  /// [emptyTitle]/[emptySubtitle] instead.
  final String title;
  final String? note;
  final String? updatedDisplay;
  final VoidCallback? onTap;
  final String? emptyTitle;
  final String? emptySubtitle;

  /// Read-only explanation shown under the note (archived categories).
  final String? readOnlyHint;

  const BudgetNoteCard({
    super.key,
    required this.title,
    required this.note,
    this.updatedDisplay,
    this.onTap,
    this.emptyTitle,
    this.emptySubtitle,
    this.readOnlyHint,
  });

  bool get _readOnly => onTap == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = note?.trim() ?? '';
    final hasNote = text.isNotEmpty;

    if (!hasNote && _readOnly) {
      return readOnlyHint == null
          ? const SizedBox.shrink()
          : Text(
              readOnlyHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            );
    }

    return hasNote
        ? _SavedNote(
            title: title,
            note: text,
            updatedDisplay: updatedDisplay,
            readOnlyHint: readOnlyHint,
            onTap: onTap,
          )
        : _EmptyNote(
            emptyTitle: emptyTitle ?? l10n.budgetNoteEmptyTitle,
            emptySubtitle: emptySubtitle ?? l10n.budgetNoteEmptySubtitle,
            onTap: onTap!,
          );
  }
}

class _EmptyNote extends StatelessWidget {
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback onTap;

  const _EmptyNote({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(BudgetNoteCard._radius);

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
            onTap: onTap,
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
                          emptyTitle,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          emptySubtitle,
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
}

class _SavedNote extends StatelessWidget {
  final String title;
  final String note;
  final String? updatedDisplay;
  final String? readOnlyHint;
  final VoidCallback? onTap;

  const _SavedNote({
    required this.title,
    required this.note,
    required this.updatedDisplay,
    required this.readOnlyHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final radius = BorderRadius.circular(BudgetNoteCard._radius);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onTap,
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
                        title,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ),
                    if (onTap != null) ...[
                      SizedBox(width: spacing.sm),
                      IconButton.filledTonal(
                        key: const ValueKey('budget-note-edit'),
                        onPressed: onTap,
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
                if (updatedDisplay != null) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    l10n.budgetNoteUpdatedOn(updatedDisplay!),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                if (readOnlyHint != null) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    readOnlyHint!,
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

/// Opens the modal review-note editor.
///
/// [onSave] persists the draft and reports the outcome; [title] is the sheet
/// heading and the saved card's header, while [contextLabel] names the scope
/// (month or category) in the pill next to it.
///
/// Returns the saved note text (an empty string when the note was deleted), or
/// null when the sheet was dismissed without saving.
Future<String?> showBudgetNoteSheet(
  BuildContext context, {
  required String title,
  required String? contextLabel,
  required String? initialNote,
  required Future<Result<void>> Function(String note) onSave,
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
    builder: (_) => BudgetNoteSheet(
      title: title,
      contextLabel: contextLabel,
      initialNote: initialNote,
      onSave: onSave,
    ),
  );
}

/// Modal editor for a review note.
///
/// The sheet owns only the draft and the write call; the summary stream and the
/// caller's card own the persisted value.
class BudgetNoteSheet extends StatefulWidget {
  final String title;
  final String? contextLabel;
  final String? initialNote;
  final Future<Result<void>> Function(String note) onSave;

  const BudgetNoteSheet({
    super.key,
    required this.title,
    required this.contextLabel,
    required this.initialNote,
    required this.onSave,
  });

  @override
  State<BudgetNoteSheet> createState() => _BudgetNoteSheetState();
}

class _BudgetNoteSheetState extends State<BudgetNoteSheet> {
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
    final result = await widget.onSave(raw);
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

    final deleted = await _persist('');
    if (!mounted || !deleted) return;

    Navigator.of(context).pop('');
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.budgetNoteDeleted),
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () {
            unawaited(widget.onSave(previous ?? ''));
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
                          widget.title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (widget.contextLabel != null) ...[
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
                            widget.contextLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
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
            padding: EdgeInsets.all(spacing.md),
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
