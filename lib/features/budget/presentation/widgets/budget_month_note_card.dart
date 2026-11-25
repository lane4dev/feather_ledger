import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import '../../domain/services/budget_service.dart';
import '../../domain/value_objects/budget_value_objects.dart';
import '../mappers/budget_review_ui_mapper.dart';
import '../view_model/budget_view_model.dart';
import 'budget_note_card.dart';

/// Month-level review note on the L2 review page.
///
/// The card keeps an optimistic copy of the note it just saved: the summary
/// stream follows a moment later with the persisted write time.
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
    final l10n = AppLocalizations.of(context)!;
    final saved = await showBudgetNoteSheet(
      context,
      title: l10n.budgetMonthNoteLabel,
      contextLabel: widget.monthLabel,
      initialNote: _note,
      onSave: (note) =>
          ref.read(budgetViewModelProvider.notifier).saveReviewNote(
                currencyCode: widget.currencyCode,
                month: widget.month,
                note: note,
              ),
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
    return BudgetNoteCard(
      title: l10n.budgetMonthNoteLabel,
      note: _note,
      updatedDisplay: _updatedDisplay,
      onTap: _openEditor,
    );
  }
}
